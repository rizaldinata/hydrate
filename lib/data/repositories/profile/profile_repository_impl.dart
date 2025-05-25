import 'package:uuid/uuid.dart';

import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/datasources/FirestoreService.dart';
import 'package:hydrate/data/models/pengguna_model.dart';
import 'package:hydrate/data/repositories/profile/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class ProfileRepositoryImpl implements ProfileRepository {
  final DatabaseHelper _dbHelper;
  final FirestoreService _firestoreService;
  final Uuid _uuid = Uuid();
  final FirebaseAuth _auth;

  ProfileRepositoryImpl({
    required DatabaseHelper dbHelper,
    required FirestoreService firestoreService,
    required FirebaseAuth auth,
  })  : _dbHelper = dbHelper,
        _firestoreService = firestoreService,
        _auth = auth;

  @override
  Future<int> tambahPenggunaDanProfilLokal(String nama, String jenisKelamin, double beratBadan, String jamBangun, String jamTidur) async {
    final db = await _dbHelper.database;
    try {
      return await db.transaction((txn) async {
        int idPengguna = await txn.insert('pengguna', {
          'nama_pengguna': nama,
          'firebase_uid': null,
          'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
          'is_synced': 0,
        });

        if (idPengguna <= 0) return -1;

        Map<String, dynamic> profilDataToInsert = {
          'sync_id': _uuid.v4(),
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

        if (idProfil <= 0) return -1;
        
        await SessionManager().saveUserId(idPengguna);
        return idPengguna;
      });
    } catch (e, s) {
      print("ProfileRepositoryImpl: Gagal menambahkan pengguna dan profil lokal: $e");
      print("Stacktrace: $s");
      return -1;
    }
  }

  @override
  Future<Map<String, dynamic>> setupNewLocalUser({
    required String firebaseUid,
    required String namaPengguna,
    required Map<String, dynamic> dataProfil,
  }) async {
    final db = await _dbHelper.database;
    int? localPenggunaId;
    String? profilSyncId;

    await db.transaction((txn) async {
      Map<String, dynamic> penggunaSqliteData = {
        'nama_pengguna': namaPengguna,
        'firebase_uid': firebaseUid,
        'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      };
      localPenggunaId = await txn.insert('pengguna', penggunaSqliteData);
      if (localPenggunaId! <= 0) throw Exception("Gagal menyimpan pengguna lokal.");

      Map<String, dynamic> profilToInsert = Map.from(dataProfil);
      profilToInsert.remove('sync_id');
      profilToInsert.remove('fk_id_pengguna');
      
      Map<String, dynamic> insertedProfil = await _dbHelper.insertProfilPenggunaWithTxn(txn, profilToInsert, localPenggunaId!);
      if (insertedProfil['id'] == null || (insertedProfil['id'] as int) <= 0) {
        throw Exception("Gagal menyimpan profil pengguna lokal.");
      }
      profilSyncId = insertedProfil['sync_id'] as String?;
    });
    
    return {'localPenggunaId': localPenggunaId, 'profilSyncId': profilSyncId};
  }

  @override
  Future<Pengguna?> getPenggunaById(int id) async {
    final db = await _dbHelper.database;
    try {
      final maps = await db.query('pengguna', where: 'id = ?', whereArgs: [id]);
      return maps.isNotEmpty ? Pengguna.fromMap(maps.first) : null;
    } catch (e) {
      print("ProfileRepositoryImpl: Error saat mengambil pengguna: $e");
      return null;
    }
  }

  @override
  Future<Pengguna?> getLocalPenggunaByFirebaseUid(String firebaseUid) async {
    final map = await _dbHelper.getPenggunaByFirebaseUid(firebaseUid);
    return map != null ? Pengguna.fromMap(map) : null;
  }

  @override
  Future<Map<String, dynamic>?> getLocalUserProfile(int localPenggunaId) async {
    return await _dbHelper.getProfilPenggunaByLocalId(localPenggunaId);
  }

  @override
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

  @override
  Future<bool> updateLokalDanSinkronProfil({
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
          return true;
        }
      }
      return false;
    } catch (e) {
      print("ProfileRepositoryImpl: Error saat update profil: $e");
      return false;
    }
  }
  
  @override
  Future<bool> setupNewUserProfile({
    required String namaPengguna,
    required Map<String, dynamic> dataProfil,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception("Tidak ada pengguna yang login di Firebase.");
      }

      int? localPenggunaId = await _dbHelper.getLocalPenggunaId(firebaseUser.uid);

      // Jika pengguna belum ada di DB lokal, buat record baru
      localPenggunaId ??= await _dbHelper.insertPengguna({
          'nama_pengguna': namaPengguna,
          'firebase_uid': firebaseUser.uid,
          'last_modified_locally': DateTime.now().millisecondsSinceEpoch,
          'is_synced': 1, // Langsung dianggap sinkron
        });

      // Pastikan kita punya ID lokal untuk melanjutkan
      if (localPenggunaId <= 0) {
        throw Exception("Gagal membuat atau menemukan record pengguna lokal.");
      }
      
      // Simpan profil ke SQLite
      final insertedProfil = await _dbHelper.insertProfilPengguna(dataProfil, localPenggunaId);
      final profilSyncId = insertedProfil['sync_id'] as String?;

      if (profilSyncId == null) {
        throw Exception("Gagal menyimpan profil lokal.");
      }
      
      // Simpan session
      await SessionManager().saveUserId(localPenggunaId);
      
      // Sinkronkan ke Firestore
      final profilDariDb = await _dbHelper.getProfilPenggunaBySyncId(profilSyncId);
      if (profilDariDb != null) {
        await _firestoreService.saveProfilPengguna(profilDariDb, profilSyncId);
        await _dbHelper.markAsSynced('profil_pengguna', profilSyncId);
      }

      return true;

    } catch (e) {
      print("ProfileRepositoryImpl: Error saat setupNewUserProfile: $e");
      return false;
    }
  }
}