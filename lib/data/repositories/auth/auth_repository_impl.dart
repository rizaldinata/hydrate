import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/repositories/auth/auth_repository.dart';
import 'package:hydrate/data/repositories/profile/profile_repository.dart';
import 'package:hydrate/data/repositories/sync/sync_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth _auth;
  final DatabaseHelper _dbHelper;
  final SharedPreferences _prefs;
  
  // Dependensi ke repositori lain untuk koordinasi
  final ProfileRepository _profileRepository;
  final SyncRepository _syncRepository;

  AuthRepositoryImpl({
    required fb_auth.FirebaseAuth auth,
    required DatabaseHelper dbHelper,
    required SharedPreferences prefs,
    required ProfileRepository profileRepository,
    required SyncRepository syncRepository,
  })  : _auth = auth,
        _dbHelper = dbHelper,
        _prefs = prefs,
        _profileRepository = profileRepository,
        _syncRepository = syncRepository;

  @override
  fb_auth.User? get currentUser => _auth.currentUser;

  @override
  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<bool> isPenggunaTerdaftarLokal() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> result = await db.query(
        'pengguna',
        limit: 1,
        columns: ['id'],
      );
      return result.isNotEmpty;
    } catch (e, stackTrace) {
      print('[ERROR] Gagal memeriksa pengguna terdaftar: $e');
      print('[STACK TRACE] $stackTrace');
      return false;
    }
  }

  @override
  Future<fb_auth.User?> signInWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on fb_auth.FirebaseAuthException catch (e) {
      print("AuthRepositoryImpl: Error signIn - ${e.message} (code: ${e.code})");
      throw Exception("Gagal login: ${e.message}");
    } catch (e) {
      print("AuthRepositoryImpl: Error umum signIn - $e");
      throw Exception("Terjadi kesalahan saat login.");
    }
  }

  @override
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

      // 2. Simpan ke SQLite menggunakan ProfileRepository
      final result = await _profileRepository.setupNewLocalUser(
        firebaseUid: firebaseUser.uid,
        namaPengguna: namaPengguna,
        dataProfil: dataProfil,
      );

      final localPenggunaId = result['localPenggunaId'];
      final profilSyncId = result['profilSyncId'];
      
      if (localPenggunaId == null || profilSyncId == null) {
        throw Exception("Gagal mendapatkan ID lokal atau sync_id setelah transaksi SQLite.");
      }
      
      // Simpan session lokal
      await SessionManager().saveUserId(localPenggunaId);
      
      // 3. Sinkronkan ke Firestore menggunakan SyncRepository
      await _syncRepository.syncInitialRegistrationData(
        firebaseUid: firebaseUser.uid, 
        localPenggunaId: localPenggunaId, 
        profilSyncId: profilSyncId
      );

      return true;

    } on fb_auth.FirebaseAuthException catch (e) {
      print("AuthRepositoryImpl: FirebaseAuthException saat registrasi: ${e.code} - ${e.message}");
      throw Exception("Gagal registrasi: ${e.message}");
    } catch (e, s) {
      print("AuthRepositoryImpl: Exception umum saat registrasi: $e");
      print(s);
      throw Exception("Terjadi kesalahan saat registrasi.");
    }
  }

  @override
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
    print("AuthRepositoryImpl: Pengguna signOut, data lokal dan session dibersihkan.");
  }
}