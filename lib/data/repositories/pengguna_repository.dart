import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:uuid/uuid.dart';

// Sesuaikan path jika berbeda
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/datasources/FirestoreService.dart';
import 'package:hydrate/data/models/pengguna_model.dart';

class PenggunaRepository {
  final DatabaseHelper _dbHelper;
  final fb_auth.FirebaseAuth _auth;
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;
  final Uuid _uuid = Uuid();

  PenggunaRepository({
    required fb_auth.FirebaseAuth auth,
    required DatabaseHelper dbHelper,
    required FirestoreService firestoreService,
    required SharedPreferences prefs,
  })  : _auth = auth,
        _dbHelper = dbHelper,
        _firestoreService = firestoreService,
        _prefs = prefs;

  fb_auth.User? get currentUser => _auth.currentUser;

  // --- PENGECEKAN PENGGUNA TERDAFTAR ---
  
  Future<bool> isPenggunaTerdaftar() async {
    try {
      print('[DEBUG] Memulai pengecekan pengguna terdaftar');

      final db = await _dbHelper.database;
      if (db == null || !db.isOpen) {
        print('[ERROR] Koneksi database tidak valid atau tertutup');
        return false;
      }

      print('[DEBUG] Mengeksekusi query ke tabel pengguna');
      final List<Map<String, dynamic>> result = await db.query(
        'pengguna',
        limit: 1,
        columns: ['id'],
      );

      print('[DEBUG] Hasil query: ${result.length} record ditemukan');
      if (result.isNotEmpty) {
        print('[DEBUG] Data pengguna pertama: ${result.first}');
      }

      return result.isNotEmpty;
    } catch (e, stackTrace) {
      print('[ERROR] Gagal memeriksa pengguna terdaftar: $e');
      print('[STACK TRACE] $stackTrace');
      return false;
    } finally {
      print('[DEBUG] Proses pengecekan pengguna selesai');
    }
  }

  // --- TAMBAH PENGGUNA DAN PROFIL (DIPERBAIKI) ---
  
  Future<int> tambahPenggunaDanProfil(String nama, String jenisKelamin,
      double beratBadan, String jamBangun, String jamTidur) async {
    final db = await _dbHelper.database;

    try {
      return await db.transaction((txn) async {
        // Insert ke tabel pengguna
        int idPengguna = await txn.insert('pengguna', {
          'nama_pengguna': nama,
          'firebase_uid': null, // Untuk pengguna lokal tanpa Firebase
          'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
          'is_synced': 0,
        });
        print("Insert ke 'pengguna' berhasil dengan ID: $idPengguna");

        if (idPengguna <= 0) {
          print("Gagal menyisipkan pengguna.");
          return -1;
        }

        // Membuat sync_id untuk profil
        String syncIdProfil = _uuid.v4();

        // Insert ke tabel profil_pengguna DENGAN sync_id dan kolom sinkronisasi
        Map<String, dynamic> profilDataToInsert = {
          'sync_id': syncIdProfil,
          'fk_id_pengguna': idPengguna,
          'jenis_kelamin': jenisKelamin,
          'berat_badan': beratBadan,
          'jam_bangun': jamBangun,
          'jam_tidur': jamTidur,
          'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
          'is_synced': 0,
          'is_deleted': 0,
        };

        int idProfil = await txn.insert('profil_pengguna', profilDataToInsert);
        print("Insert ke 'profil_pengguna' berhasil dengan ID: $idProfil dan sync_id: $syncIdProfil");

        if (idProfil <= 0) {
          print("Gagal menyisipkan profil pengguna.");
          return -1;
        }

        // Simpan session jika berhasil
        await SessionManager().saveUserId(idPengguna);
        print("Session berhasil disimpan dengan ID: $idPengguna");

        // Debug: Pastikan data benar-benar masuk ke database
        var penggunaBaru = await txn
            .query('pengguna', where: 'id = ?', whereArgs: [idPengguna]);
        var profilBaru = await txn.query('profil_pengguna',
            where: 'fk_id_pengguna = ?', whereArgs: [idPengguna]);

        print("Data pengguna yang baru dimasukkan: $penggunaBaru");
        print("Data profil yang baru dimasukkan: $profilBaru");

        print("Berhasil menambahkan pengguna dengan ID: $idPengguna");
        return idPengguna;
      });
    } catch (e, s) {
      print("Gagal menambahkan pengguna dan profil (exception): $e");
      print("Stacktrace: $s");
      return -1;
    }
  }

  // --- AUTENTIKASI ---

  Future<fb_auth.User?> signInWithEmailPassword(String email, String password) async {
    try {
      fb_auth.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on fb_auth.FirebaseAuthException catch (e) {
      print("PenggunaRepository: Error signIn - ${e.message} (code: ${e.code})");
      throw Exception("Gagal login: ${e.message}");
    } catch (e) {
      print("PenggunaRepository: Error umum signIn - $e");
      throw Exception("Terjadi kesalahan saat login.");
    }
  }

  Future<bool> registerAndSetupUser({
    required String email,
    required String password,
    required String namaPengguna,
    required Map<String, dynamic> dataProfil,
  }) async {
    try {
      // 1. Buat pengguna di Firebase Authentication
      fb_auth.UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      fb_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception("Gagal membuat pengguna di Firebase Auth.");
      }
      print("PenggunaRepository: Pengguna Firebase Auth dibuat UID: ${firebaseUser.uid}");

      // 2. Simpan ke SQLite dalam satu transaksi
      final db = await _dbHelper.database;
      int? localPenggunaId;
      String? profilSyncId;

      await db.transaction((txn) async {
        // a. Simpan ke tabel 'pengguna' SQLite
        Map<String, dynamic> penggunaSqliteData = {
          'nama_pengguna': namaPengguna,
          'firebase_uid': firebaseUser.uid,
          'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
          'is_synced': 0,
        };
        localPenggunaId = await txn.insert('pengguna', penggunaSqliteData);
        if (localPenggunaId! <= 0) throw Exception("Gagal menyimpan pengguna lokal ke SQLite.");
        print("PenggunaRepository: Pengguna lokal disimpan, ID: $localPenggunaId");

        // b. Simpan ke tabel 'profil_pengguna' SQLite
        Map<String, dynamic> profilToInsert = Map.from(dataProfil);
        profilToInsert.remove('sync_id');
        profilToInsert.remove('fk_id_pengguna');

        Map<String, dynamic> insertedProfil = await _dbHelper.insertProfilPenggunaWithTxn(txn, profilToInsert, localPenggunaId!);
        if (insertedProfil['id'] == null || (insertedProfil['id'] as int) <= 0) {
          throw Exception("Gagal menyimpan profil pengguna lokal ke SQLite.");
        }
        profilSyncId = insertedProfil['sync_id'] as String?;
        print("PenggunaRepository: Profil lokal disimpan, ID: ${insertedProfil['id']}, SyncID: $profilSyncId");

        // c. Simpan session lokal
        await SessionManager().saveUserId(localPenggunaId!);
        print("PenggunaRepository: Session Manager UserId disimpan: $localPenggunaId");
      });

      if (localPenggunaId == null || profilSyncId == null) {
        throw Exception("Gagal mendapatkan ID lokal atau sync_id setelah transaksi SQLite.");
      }

      // 3. Sinkronkan ke Firestore
      final penggunaDariDb = await _dbHelper.getPenggunaByFirebaseUid(firebaseUser.uid);
      final profilDariDb = await _dbHelper.getProfilPenggunaByLocalId(localPenggunaId!);

      bool penggunaSynced = false;
      bool profilSynced = false;

      if (penggunaDariDb != null) {
        await _dbHelper.markAsSyncedByLocalId('pengguna', localPenggunaId!);
        penggunaSynced = true;
      }
      
      if (profilDariDb != null && profilSyncId != null) {
        await _firestoreService.saveProfilPengguna(profilDariDb, profilSyncId!);
        await _dbHelper.markAsSynced('profil_pengguna', profilSyncId!);
        profilSynced = true;
      }

      if (penggunaSynced && profilSynced) {
         print("PenggunaRepository: Registrasi dan sinkronisasi awal ke Firestore berhasil.");
         return true;
      } else {
        print("PenggunaRepository: Registrasi SQLite berhasil, namun sinkronisasi awal ke Firestore mungkin belum lengkap.");
        return true;
      }

    } on fb_auth.FirebaseAuthException catch (e) {
      print("PenggunaRepository: FirebaseAuthException saat registrasi: ${e.code} - ${e.message}");
      throw Exception("Gagal registrasi: ${e.message}");
    } catch (e, s) {
      print("PenggunaRepository: Exception umum saat registrasi: $e");
      print(s);
      throw Exception("Terjadi kesalahan saat registrasi.");
    }
  }

  Future<bool> setupNewUserProfile({
  required String namaPengguna, // Untuk tabel 'pengguna' dan mungkin display name
  required Map<String, dynamic> dataProfil, // jenisKelamin, beratBadan, jamBangun, jamTidur, email_kontak (opsional)
}) async {
  try {
    fb_auth.User? firebaseUser = _auth.currentUser; // Dapatkan pengguna yang SEDANG LOGIN

    if (firebaseUser == null) {
      print("PenggunaRepository: Tidak ada pengguna yang login. Tidak bisa setup profil.");
      throw Exception("Pengguna tidak login. Tidak bisa setup profil.");
    }
    // ... (sisa logika untuk menyimpan ke SQLite dan sinkronisasi ke Firestore menggunakan firebaseUser.uid) ...
    // ... (seperti pada kode PenggunaRepository.dart final yang saya berikan sebelumnya) ...
    return true; // jika semua berhasil
  } catch (e, s) {
    print("PenggunaRepository: Exception umum saat setupNewUserProfile: $e");
    print("Stacktrace Repository: $s");
    return false;
  }
}

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    await _auth.signOut();
    if (uid != null) {
      final localId = await _dbHelper.getLocalPenggunaId(uid);
      if (localId != null) {
        await _dbHelper.clearUserData(localId);
      }
      await _prefs.remove('isDataRestored_$uid');
    }
    await SessionManager().clearSession();
    print("PenggunaRepository: Pengguna signOut, data lokal dan session dibersihkan.");
  }

  // --- INISIALISASI DAN SINKRONISASI DATA ---

  Future<bool> handleUserLoginInitialization(fb_auth.User firebaseUser) async {
    try {
      print("PenggunaRepository: Memulai inisialisasi untuk user ${firebaseUser.uid}");
      int? localPenggunaId = await _dbHelper.getLocalPenggunaId(firebaseUser.uid);

      if (localPenggunaId == null) {
        print("PenggunaRepository: Pengguna baru di perangkat ini. Membuat record SQLite...");
        String namaPengguna = firebaseUser.displayName ?? firebaseUser.email ?? "Pengguna";
        Map<String, dynamic> penggunaSqliteData = {
          'nama_pengguna': namaPengguna,
          'firebase_uid': firebaseUser.uid,
          'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
          'is_synced': 0,
        };
        localPenggunaId = await _dbHelper.insertPengguna(penggunaSqliteData);
        print("PenggunaRepository: Record pengguna SQLite dibuat dengan ID: $localPenggunaId");
      } else {
        print("PenggunaRepository: Record pengguna SQLite sudah ada, ID: $localPenggunaId");
      }

      bool isDataRestored = _prefs.getBool('isDataRestored_${firebaseUser.uid}') ?? false;

      if (!isDataRestored) {
        print("PenggunaRepository: Memulai proses restore data dari Firestore...");
        
        final Map<String, dynamic>? profilFs =
    await _firestoreService.getUserMainProfileFromSubcollection();

      if (profilFs != null) {
          // Pastikan profilFs memiliki 'sync_id' yang di-set oleh getUserMainProfileFromSubcollection
          // (yaitu ID dokumen dari Firestore)
          await _dbHelper.insertOrReplaceProfilFromFirestore(profilFs, localPenggunaId!);
          print("PenggunaRepository: Profil di-restore dari Firestore. Sync ID: ${profilFs['sync_id']}");
           // --- TAMBAHKAN PENGECEKAN INI ---
  final profilDariSQLiteSetelahRestore = await _dbHelper.getProfilPenggunaByLocalId(localPenggunaId);
  if (profilDariSQLiteSetelahRestore != null) {
    print("PenggunaRepository: Verifikasi - Profil DITEMUKAN di SQLite setelah restore: $profilDariSQLiteSetelahRestore");
  } else {
    print("PenggunaRepository: Verifikasi - Profil TIDAK DITEMUKAN di SQLite setelah restore untuk localPenggunaId: $localPenggunaId !");
  }
        } else {
          print("PenggunaRepository: Tidak ada profil utama ditemukan di Firestore untuk di-restore.");
        }

        // Restore Riwayat Hidrasi (kode Anda sebelumnya untuk bagian ini kemungkinan sudah benar)
        List<Map<String, dynamic>> allRiwayatFs = await _firestoreService.getAllRiwayatHidrasi();
        for (var itemFs in allRiwayatFs) {
          if (itemFs['is_deleted'] != true) {
            await _dbHelper.insertOrReplaceRiwayatFromFirestore(itemFs, localPenggunaId!);
          }
        }
        print("PenggunaRepository: ${allRiwayatFs.length} item riwayat di-restore.");

        // Restore Target Hidrasi (kode Anda sebelumnya untuk bagian ini kemungkinan sudah benar)
        List<Map<String, dynamic>> allTargetFs = await _firestoreService.getAllTargetHidrasi();
        for (var itemFs in allTargetFs) {
          if (itemFs['is_deleted'] != true) {
            await _dbHelper.insertOrReplaceTargetFromFirestore(itemFs, localPenggunaId!);
          }
        }
        print("PenggunaRepository: ${allTargetFs.length} item target di-restore.");

        await _prefs.setBool('isDataRestored_${firebaseUser.uid}', true);
        print("PenggunaRepository: Restore data dari Firestore selesai.");
      } else {
        print("PenggunaRepository: Data sudah pernah di-restore.");
      }

      await syncOfflineData(); // Pastikan metode ini juga ada dan benar
      return true;
    } catch (e, s) {
      print("PenggunaRepository: Error saat inisialisasi pengguna: $e");
      print(s);
      return false;
    }
  }

  Future<void> syncOfflineData() async {
    if (currentUser == null) {
      print("PenggunaRepository: Tidak ada pengguna login, sinkronisasi dibatalkan.");
      return;
    }
    print("PenggunaRepository: Memulai sinkronisasi data offline...");

    try {
      // Sinkronisasi Profil
      List<Map<String, dynamic>> unsyncedProfiles = await _dbHelper.getUnsyncedData('profil_pengguna');
      for (var profile in unsyncedProfiles) {
        await _firestoreService.saveProfilPengguna(profile, profile['sync_id']);
        await _dbHelper.markAsSynced('profil_pengguna', profile['sync_id']);
      }
      if (unsyncedProfiles.isNotEmpty) print("PenggunaRepository: ${unsyncedProfiles.length} profil disinkronkan.");

      // Sinkronisasi Riwayat Hidrasi (Batch)
      List<Map<String, dynamic>> unsyncedRiwayat = await _dbHelper.getUnsyncedData('riwayat_hidrasi');
      if (unsyncedRiwayat.isNotEmpty) {
        await _firestoreService.syncBatchToFirestore('riwayat_hidrasi', unsyncedRiwayat);
        for (var item in unsyncedRiwayat) {
          await _dbHelper.markAsSynced('riwayat_hidrasi', item['sync_id']);
        }
        print("PenggunaRepository: ${unsyncedRiwayat.length} item riwayat disinkronkan.");
      }

      // Sinkronisasi Target Hidrasi (Batch)
      List<Map<String, dynamic>> unsyncedTarget = await _dbHelper.getUnsyncedData('target_hidrasi');
       if (unsyncedTarget.isNotEmpty) {
        await _firestoreService.syncBatchToFirestore('target_hidrasi', unsyncedTarget);
        for (var item in unsyncedTarget) {
          await _dbHelper.markAsSynced('target_hidrasi', item['sync_id']);
        }
        print("PenggunaRepository: ${unsyncedTarget.length} item target disinkronkan.");
      }

      print("PenggunaRepository: Sinkronisasi data offline selesai.");
    } catch (e) {
      print("PenggunaRepository: Error saat sinkronisasi data offline: $e");
    }
  }

  // --- CRUD UNTUK PENGGUNA & PROFIL ---
  
  Future<Pengguna?> getPenggunaById(int id) async {
    final db = await _dbHelper.database;
    try {
      final maps = await db.query(
        'pengguna',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        Pengguna pengguna = Pengguna.fromMap(maps.first);
        print("Data pengguna ditemukan: ${pengguna.toMap()}");
        return pengguna;
      } else {
        print("Pengguna dengan ID $id tidak ditemukan.");
        return null;
      }
    } catch (e) {
      print("Error saat mengambil pengguna: $e");
      return null;
    }
  }

  Future<Pengguna?> getLocalPenggunaByFirebaseUid(String firebaseUid) async {
      final map = await _dbHelper.getPenggunaByFirebaseUid(firebaseUid);
      return map != null ? Pengguna.fromMap(map) : null;
  }

  Future<Map<String, dynamic>?> getLocalUserProfile(int localPenggunaId) async {
      return await _dbHelper.getProfilPenggunaByLocalId(localPenggunaId);
  }

  Future<int> updateNama(int userId, String newNama) async {
    final db = await _dbHelper.database;
    return await db.update(
      'pengguna',
      {
        'nama_pengguna': newNama,
        'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      }, 
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> updateLokalDanSinkronProfil({
    required int localPenggunaId,
    required String profilSyncId,
    required Map<String, dynamic> dataUpdateProfil,
  }) async {
    try {
      final Map<String, dynamic> dataUntukSqlite = Map.from(dataUpdateProfil);
      int updatedRows = await _dbHelper.updateProfilPengguna(dataUntukSqlite, profilSyncId);

      if (updatedRows > 0) {
        final profilDariDb = await _dbHelper.getProfilPenggunaBySyncId(profilSyncId);
        if (profilDariDb != null) {
          await _firestoreService.saveProfilPengguna(profilDariDb, profilSyncId);
          await _dbHelper.markAsSynced('profil_pengguna', profilSyncId);
          print("PenggunaRepository: Profil berhasil diupdate dan disinkronkan.");
          return true;
        }
      }
      print("PenggunaRepository: Gagal mengupdate profil lokal atau tidak ada perubahan.");
      return false;
    } catch (e) {
      print("PenggunaRepository: Error saat update profil: $e");
      return false;
    }
  }

  // --- CRUD UNTUK RIWAYAT HIDRASI ---
  
  Future<Map<String, dynamic>?> addRiwayatHidrasi({
    required int localPenggunaId,
    required double jumlah,
    required String tanggal,
    required String waktu,
  }) async {
    try {
      Map<String, dynamic> dataRiwayat = {
        'jumlah_hidrasi': jumlah,
        'tanggal_hidrasi': tanggal,
        'waktu_hidrasi': waktu,
      };
      Map<String, dynamic> recordDitambahkan = await _dbHelper.insertRiwayatHidrasi(dataRiwayat, localPenggunaId);
      String syncId = recordDitambahkan['sync_id'];

      // Sinkronkan ke Firestore
      await _firestoreService.saveRiwayatHidrasiItem(recordDitambahkan, syncId);
      await _dbHelper.markAsSynced('riwayat_hidrasi', syncId);
      
      print("PenggunaRepository: Riwayat hidrasi ditambahkan dan disinkronkan, syncId: $syncId");
      return recordDitambahkan;
    } catch (e) {
      print("PenggunaRepository: Error saat menambah riwayat hidrasi: $e");
      return null;
    }
  }

  Future<bool> softDeleteRiwayatHidrasi(String riwayatSyncId) async {
    try {
      int updatedRows = await _dbHelper.softDeleteRiwayatHidrasi(riwayatSyncId);
      if (updatedRows > 0) {
        await _firestoreService.softDeleteRiwayatHidrasiItem(riwayatSyncId);
        await _dbHelper.markAsSynced('riwayat_hidrasi', riwayatSyncId);
        print("PenggunaRepository: Riwayat hidrasi di-soft-delete dan disinkronkan, syncId: $riwayatSyncId");
        return true;
      }
      return false;
    } catch (e) {
      print("PenggunaRepository: Error saat soft delete riwayat hidrasi: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllLocalRiwayatHidrasi(int localPenggunaId) async {
      return await _dbHelper.getAllRiwayatHidrasiForPengguna(localPenggunaId);
  }

  // --- CRUD UNTUK TARGET HIDRASI ---
  
  Future<Map<String, dynamic>?> saveOrUpdateTargetHidrasi({
    required int localPenggunaId,
    required String tanggal,
    required double target,
    double? totalHarian,
    double? persentase,
  }) async {
    try {
      Map<String, dynamic> dataTarget = {
        'sync_id': tanggal,
        'target_hidrasi': target,
        'tanggal_hidrasi': tanggal,
        'total_hidrasi_harian': totalHarian ?? 0.0,
        'persentase_hidrasi': persentase ?? 0.0,
      };
      Map<String, dynamic> targetDisimpan = await _dbHelper.insertOrReplaceTargetHidrasi(dataTarget, localPenggunaId);

      // Sinkronkan ke Firestore
      await _firestoreService.saveTargetHidrasi(targetDisimpan, tanggal);
      await _dbHelper.markAsSynced('target_hidrasi', tanggal);

      print("PenggunaRepository: Target hidrasi disimpan/diupdate dan disinkronkan untuk tanggal $tanggal");
      return targetDisimpan;
    } catch (e) {
      print("PenggunaRepository: Error saat menyimpan target hidrasi: $e");
      return null;
    }
  }

   Future<Map<String, dynamic>?> getLocalTargetHidrasi(int localPenggunaId, String tanggal) async {
      return await _dbHelper.getTargetHidrasiByTanggal(localPenggunaId, tanggal);
  }

  // --- GETTER UNTUK DEPENDENCIES ---
  
  fb_auth.FirebaseAuth get auth => _auth;
  DatabaseHelper get dbHelper => _dbHelper;
  FirestoreService get firestoreService => _firestoreService;
  SharedPreferences get prefs => _prefs;
}