import '../models/profil_pengguna_model.dart';
import '../data/repositories/profil_pengguna_repository.dart';

class ProfilPenggunaController {
  final ProfilPenggunaRepository _repository = ProfilPenggunaRepository();

  // tambah profil pengguna (kek e nanti ngga kepake)
  Future<int> tambahProfilPengguna(ProfilPengguna profil) async {
    return await _repository.tambahProfilPengguna(profil);
  }

  // ini nanti buat edit profil pengguna
}
