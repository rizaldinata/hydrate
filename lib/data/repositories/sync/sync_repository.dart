import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

abstract class SyncRepository {
  /// Menangani semua proses yang diperlukan saat pengguna login:
  /// membuat record lokal jika belum ada, restore data dari Firestore,
  /// dan sinkronisasi data offline.
  Future<bool> handleUserLoginInitialization(fb_auth.User firebaseUser);

  /// Mendorong semua perubahan lokal yang belum tersinkronisasi ke Firestore.
  Future<void> syncOfflineData();
  
  /// Melakukan sinkronisasi pertama kali segera setelah registrasi berhasil.
  Future<void> syncInitialRegistrationData({
    required String firebaseUid,
    required int localPenggunaId,
    required String profilSyncId,
  });
}