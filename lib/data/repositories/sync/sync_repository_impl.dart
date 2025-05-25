import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/datasources/FirestoreService.dart';
import 'package:hydrate/data/repositories/sync/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  final DatabaseHelper _dbHelper;
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;
  final fb_auth.FirebaseAuth _auth; // Dibutuhkan untuk `currentUser`

  SyncRepositoryImpl({
    required DatabaseHelper dbHelper,
    required FirestoreService firestoreService,
    required SharedPreferences prefs,
    required fb_auth.FirebaseAuth auth,
  })  : _dbHelper = dbHelper,
        _firestoreService = firestoreService,
        _prefs = prefs,
        _auth = auth;

  @override
  Future<bool> handleUserLoginInitialization(fb_auth.User firebaseUser) async {
    try {
      int? localPenggunaId = await _dbHelper.getLocalPenggunaId(firebaseUser.uid);

      if (localPenggunaId == null) {
        String namaPengguna = firebaseUser.displayName ?? firebaseUser.email ?? "Pengguna";
        Map<String, dynamic> penggunaSqliteData = {
          'nama_pengguna': namaPengguna,
          'firebase_uid': firebaseUser.uid,
          'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
          'is_synced': 1, // Anggap sudah sinkron karena ditarik dari Auth
        };
        localPenggunaId = await _dbHelper.insertPengguna(penggunaSqliteData);
        print("SyncRepository: Record pengguna SQLite dibuat dengan ID: $localPenggunaId");
      } else {
        print("SyncRepository: Record pengguna SQLite sudah ada, ID: $localPenggunaId");
      }

      bool isDataRestored = _prefs.getBool('isDataRestored_${firebaseUser.uid}') ?? false;

      if (!isDataRestored) {
        print("SyncRepository: Memulai proses restore data dari Firestore...");
        
        final Map<String, dynamic>? profilFs = await _firestoreService.getUserMainProfileFromSubcollection();
        if (profilFs != null) {
          await _dbHelper.insertOrReplaceProfilFromFirestore(profilFs, localPenggunaId);
          print("SyncRepository: Profil di-restore dari Firestore. Sync ID: ${profilFs['sync_id']}");
        }

        List<Map<String, dynamic>> allRiwayatFs = await _firestoreService.getAllRiwayatHidrasi();
        for (var itemFs in allRiwayatFs) {
          if (itemFs['is_deleted'] != true) {
            await _dbHelper.insertOrReplaceRiwayatFromFirestore(itemFs, localPenggunaId);
          }
        }
        print("SyncRepository: ${allRiwayatFs.length} item riwayat di-restore.");

        List<Map<String, dynamic>> allTargetFs = await _firestoreService.getAllTargetHidrasi();
        for (var itemFs in allTargetFs) {
          if (itemFs['is_deleted'] != true) {
            await _dbHelper.insertOrReplaceTargetFromFirestore(itemFs, localPenggunaId!);
          }
        }
        print("SyncRepository: ${allTargetFs.length} item target di-restore.");

        await _prefs.setBool('isDataRestored_${firebaseUser.uid}', true);
        print("SyncRepository: Restore data dari Firestore selesai.");
      } else {
        print("SyncRepository: Data sudah pernah di-restore, sinkronisasi offline akan dijalankan.");
      }

      await syncOfflineData();
      return true;
    } catch (e, s) {
      print("SyncRepository: Error saat inisialisasi pengguna: $e");
      print(s);
      return false;
    }
  }

  @override
  Future<void> syncOfflineData() async {
    if (_auth.currentUser == null) {
      print("SyncRepository: Tidak ada pengguna login, sinkronisasi dibatalkan.");
      return;
    }
    print("SyncRepository: Memulai sinkronisasi data offline...");

    try {
      // Sinkronisasi Profil
      List<Map<String, dynamic>> unsyncedProfiles = await _dbHelper.getUnsyncedData('profil_pengguna');
      for (var profile in unsyncedProfiles) {
        await _firestoreService.saveProfilPengguna(profile, profile['sync_id']);
        await _dbHelper.markAsSynced('profil_pengguna', profile['sync_id']);
      }
      if (unsyncedProfiles.isNotEmpty) print("SyncRepository: ${unsyncedProfiles.length} profil disinkronkan.");

      // Sinkronisasi Riwayat Hidrasi (Batch)
      List<Map<String, dynamic>> unsyncedRiwayat = await _dbHelper.getUnsyncedData('riwayat_hidrasi');
      if (unsyncedRiwayat.isNotEmpty) {
        await _firestoreService.syncBatchToFirestore('riwayat_hidrasi', unsyncedRiwayat);
        for (var item in unsyncedRiwayat) {
          await _dbHelper.markAsSynced('riwayat_hidrasi', item['sync_id']);
        }
        print("SyncRepository: ${unsyncedRiwayat.length} item riwayat disinkronkan.");
      }

      // Sinkronisasi Target Hidrasi (Batch)
      List<Map<String, dynamic>> unsyncedTarget = await _dbHelper.getUnsyncedData('target_hidrasi');
      if (unsyncedTarget.isNotEmpty) {
        await _firestoreService.syncBatchToFirestore('target_hidrasi', unsyncedTarget);
        for (var item in unsyncedTarget) {
          await _dbHelper.markAsSynced('target_hidrasi', item['sync_id']);
        }
        print("SyncRepository: ${unsyncedTarget.length} item target disinkronkan.");
      }

      print("SyncRepository: Sinkronisasi data offline selesai.");
    } catch (e) {
      print("SyncRepository: Error saat sinkronisasi data offline: $e");
    }
  }

  @override
  Future<void> syncInitialRegistrationData({
    required String firebaseUid,
    required int localPenggunaId,
    required String profilSyncId,
  }) async {
    try {
      final penggunaDariDb = await _dbHelper.getPenggunaByFirebaseUid(firebaseUid);
      final profilDariDb = await _dbHelper.getProfilPenggunaByLocalId(localPenggunaId);

      // Pada registrasi awal, pengguna tidak perlu di-sync ke Firestore
      // karena datanya (nama, uid) sudah ada di Auth. Cukup tandai sudah sinkron.
      if (penggunaDariDb != null) {
        await _dbHelper.markAsSyncedByLocalId('pengguna', localPenggunaId);
      }
      
      if (profilDariDb != null) {
        await _firestoreService.saveProfilPengguna(profilDariDb, profilSyncId);
        await _dbHelper.markAsSynced('profil_pengguna', profilSyncId);
        print("SyncRepository: Sinkronisasi awal profil ke Firestore berhasil.");
      }
    } catch (e) {
      print("SyncRepository: Gagal melakukan sinkronisasi data awal: $e");
      // Tidak melempar error agar tidak menggagalkan proses registrasi
    }
  }
}