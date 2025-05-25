import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

abstract class AuthRepository {
  // Mendapatkan status pengguna saat ini dari Firebase Auth
  fb_auth.User? get currentUser;

  // Stream untuk memantau perubahan status otentikasi
  Stream<fb_auth.User?> get authStateChanges;

  // Memeriksa apakah ada pengguna yang sudah terdaftar di database lokal
  Future<bool> isPenggunaTerdaftarLokal();

  // Proses login dengan email dan password
  Future<fb_auth.User?> signInWithEmailPassword(String email, String password);

  // Proses registrasi pengguna baru
  Future<bool> registerAndSetupUser({
    required String email,
    required String password,
    required String namaPengguna,
    required Map<String, dynamic> dataProfil,
  });

  // Proses logout
  Future<void> signOut();
}