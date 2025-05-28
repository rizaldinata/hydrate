import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/data/repositories/profil_pengguna_repository.dart';
import 'package:hydrate/data/models/profil_pengguna_model.dart';

class ProfilPenggunaController {
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

      return result1 > 0 && result2 > 0;
    } catch (e) {
      print("Error updating profile: $e");
      throw Exception('Gagal mengupdate profil: $e');
    }
  }
  
  // Method lama dipertahankan untuk backward compatibility
  Future<bool> updateProfilDanNama({
    required int userId,
    required String nama,
    required String jenisKelamin,
    required double beratBadan,
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
      );
    } catch (e) {
      print("Error in updateProfilDanNama: $e");
      return false;
    }
  }
}