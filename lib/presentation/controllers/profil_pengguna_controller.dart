import 'package:flutter/material.dart'; // Ditambahkan untuk ChangeNotifier
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/data/repositories/profil_pengguna_repository.dart';
import 'package:hydrate/data/models/profil_pengguna_model.dart';
import 'package:hydrate/presentation/controllers/target_hidrasi_controller.dart'; // Tambahkan ini

// Jika controller ini belum extends ChangeNotifier dan Anda ingin UI langsung
// merespons perubahan profil, tambahkan `extends ChangeNotifier`.
class ProfilPenggunaController extends ChangeNotifier { // Tambahkan 'extends ChangeNotifier' jika perlu
  final ProfilPenggunaRepository _profilRepo = ProfilPenggunaRepository();
  final PenggunaRepository _penggunaRepo = PenggunaRepository();

  // Method untuk mengambil data profil
  Future<ProfilPengguna?> getProfilPengguna(int fkIdPengguna) async {
    try {
      return await _profilRepo.getProfilPenggunaByUserId(fkIdPengguna);
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }

  // Update profil dengan jam bangun dan jam tidur
  Future<bool> updateProfilPenggunaLengkap({
    required int userId,
    required String nama,
    required String jenisKelamin,
    required double beratBadan,
    required String jamBangun,
    required String jamTidur,
    // TargetHidrasiController diperlukan untuk memicu update target
    required TargetHidrasiController targetController,
  }) async {
    try {
      // Update nama di tabel pengguna
      final result1 = await _penggunaRepo.updateNama(userId, nama);
      
      // Update profil di tabel profil_pengguna
      final result2 = await _profilRepo.updateProfilPenggunaLengkap(
        fkIdPengguna: userId,
        jenisKelamin: jenisKelamin,
        beratBadan: beratBadan,
        jamBangun: jamBangun,
        jamTidur: jamTidur,
      );

      if (result1 > 0 && result2 > 0) {
        // Setelah profil berhasil diupdate, panggil metode untuk
        // menghitung ulang dan memperbarui target hidrasi harian.
        await targetController.recalculateAndUpdateDailyTargetAfterProfileChange(userId);
        notifyListeners(); // Jika UI listen ke perubahan profil
        return true;
      }
      return false; // Jika salah satu update gagal
    } catch (e) {
      print("Error updating profile: $e");
      // throw Exception('Gagal mengupdate profil: $e'); // Pertimbangkan lagi apakah perlu throw
      return false;
    }
  }
  
  // Method lama dipertahankan untuk backward compatibility
  Future<bool> updateProfilDanNama({
    required int userId,
    required String nama,
    required String jenisKelamin,
    required double beratBadan,
    // TargetHidrasiController diperlukan
    required TargetHidrasiController targetController,
  }) async {
    try {
      // Dapatkan data jam bangun dan jam tidur yang sudah ada
      final currentProfile = await getProfilPengguna(userId);
      final jamBangun = currentProfile?.jamBangun ?? 'Belum diatur';
      final jamTidur = currentProfile?.jamTidur ?? 'Belum diatur';
      
      return await updateProfilPenggunaLengkap(
        userId: userId,
        nama: nama,
        jenisKelamin: jenisKelamin,
        beratBadan: beratBadan,
        jamBangun: jamBangun,
        jamTidur: jamTidur,
        targetController: targetController, // Teruskan controller
      );
    } catch (e) {
      print("Error in updateProfilDanNama: $e");
      return false;
    }
  }
}