import 'package:hydrate/data/datasources/database_helper.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import '../../data/models/profil_pengguna_model.dart';
import '../../data/repositories/profil_pengguna_repository.dart';

class ProfilPenggunaController {
  final ProfilPenggunaRepository _profilRepo = ProfilPenggunaRepository();
  final PenggunaRepository _penggunaRepo = PenggunaRepository();

  // Mengambil id user
  Future<int?> getUserId() async {
    return await DatabaseHelper().getUserId();
  }

  // Ambil nama dari tabel pengguna
  Future<String?> fetchNamaPengguna(int idPengguna) async {
    try {
      Map<String, dynamic> pengguna = await _penggunaRepo.getPenggunaById(idPengguna);
      return pengguna['nama_pengguna'];
    } catch (e) {
      print("Error mengambil nama pengguna: $e");
      return null;
    }
  }

  // Edit nama di tabel pengguna
  Future<bool> editNamaPengguna(int idPengguna, String namaBaru) async {
    return await _penggunaRepo.editNamaPengguna(idPengguna, namaBaru);
  }

  // Ambil data profil dari tabel profil_pengguna
  Future<Map<String, dynamic>> fetchProfilPengguna(int userId) async {
    try {
      return await _profilRepo.getProfilByUserId(userId);
    } catch (e) {
      print("Error mengambil profil pengguna: $e");
      return {};
    }
  }

  // Edit data profil
  Future<bool> editProfilPengguna(ProfilPengguna profil) async {
    try {
      int result = await _profilRepo.editProfilPengguna(profil);
      return result > 0;
    } catch (e) {
      print("Error mengedit profil pengguna: $e");
      return false;
    }
  }

}
