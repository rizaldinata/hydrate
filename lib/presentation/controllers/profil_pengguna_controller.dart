import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/data/repositories/profil_pengguna_repository.dart';
import 'package:hydrate/data/models/profil_pengguna_model.dart';

class ProfilPenggunaController {
  final ProfilPenggunaRepository _profilRepo = ProfilPenggunaRepository();
  final PenggunaRepository _penggunaRepo = PenggunaRepository();

  Future<ProfilPengguna?> getProfilPengguna(int fkIdPengguna) async {
    try {
      ProfilPengguna? profil = await _profilRepo.getProfilPenggunaByUserId(fkIdPengguna);
      return profil;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfilPenggunaLengkap({
    required int userId,
    required String nama,
    required String jenisKelamin,
    required double beratBadan,
    required String jamBangun,
    required String jamTidur,
  }) async {
    try {
      final result1 = await _penggunaRepo.updateNama(userId, nama);
      final result2 = await _profilRepo.updateProfilPenggunaLengkap(
        fkIdPengguna: userId,
        jenisKelamin: jenisKelamin,
        beratBadan: beratBadan,
        jamBangun: jamBangun,
        jamTidur: jamTidur,
      );

      return result1 > 0 && result2 > 0;
    } catch (_) {
      throw Exception('Gagal mengupdate profil');
    }
  }
  
  Future<bool> updateProfilDanNama({
    required int userId,
    required String nama,
    required String jenisKelamin,
    required double beratBadan,
  }) async {
    try {
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
    } catch (_) {
      return false;
    }
  }
}