import '../../data/models/profil_pengguna_model.dart';
import '../../data/repositories/profil_pengguna_repository.dart';

class ProfilPenggunaController {
  final ProfilPenggunaRepository _repository = ProfilPenggunaRepository();

  Future<ProfilPengguna?> getProfilPengguna(int userId) async {
    return await _repository.getProfilPenggunaByUserId(userId);
  }
}
