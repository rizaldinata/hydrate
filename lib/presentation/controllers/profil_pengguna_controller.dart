import 'package:hydrate/data/repositories/pengguna_repository.dart';
import '../../data/repositories/profil_pengguna_repository.dart';
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

  Future<bool> updateProfilDanNama({
    required int userId,
    required String nama,
    required String jenisKelamin,
    required double beratBadan,
  }) async {
    try {
      // Update nama di tabel pengguna
      final result1 = await _penggunaRepo.updateNama(userId, nama);
      
      // Update profil di tabel profil_pengguna
      final result2 = await _profilRepo.updateProfilPengguna(
        fkIdPengguna: userId,
        jenisKelamin: jenisKelamin,
        beratBadan: beratBadan,
      );

      return result1 > 0 && result2 > 0;
    } catch (e) {
      print("Error update: $e");
      return false;
    }
  }
}