import 'package:hydrate/data/models/pengguna_model.dart';

abstract class ProfileRepository {
  // Menambah pengguna & profil baru (untuk mode lokal/tanpa login)
  Future<int> tambahPenggunaDanProfilLokal(String nama, String jenisKelamin, double beratBadan, String jamBangun, String jamTidur);
  
  // Setup pengguna lokal baru setelah registrasi Firebase
  Future<Map<String, dynamic>> setupNewLocalUser({
    required String firebaseUid,
    required String namaPengguna,
    required Map<String, dynamic> dataProfil,
  });

  // Mendapatkan data pengguna dari DB lokal berdasarkan ID lokal
  Future<Pengguna?> getPenggunaById(int id);
  
  // Mendapatkan data pengguna dari DB lokal berdasarkan Firebase UID
  Future<Pengguna?> getLocalPenggunaByFirebaseUid(String firebaseUid);
  
  // Mendapatkan data profil dari DB lokal berdasarkan ID pengguna lokal
  Future<Map<String, dynamic>?> getLocalUserProfile(int localPenggunaId);
  
  // Mengupdate nama pengguna di DB lokal
  Future<int> updateNama(int userId, String newNama);
  
  // Mengupdate profil di DB lokal dan langsung sinkronisasi
  Future<bool> updateLokalDanSinkronProfil({
    required String profilSyncId,
    required Map<String, dynamic> dataUpdateProfil,
  });

  Future<bool> setupNewUserProfile({
    required String namaPengguna,
    required Map<String, dynamic> dataProfil,
  });
}