import 'package:hydrate/data/models/pengguna_model.dart';

import '../../data/repositories/pengguna_repository.dart';

class PenggunaController {
  final PenggunaRepository _repository = PenggunaRepository();

  Future<int> tambahPengguna(String nama, String jenisKelamin,
      double beratBadan, String jamBangun, String jamTidur) async {
    return await _repository.tambahPenggunaDanProfil(
        nama, jenisKelamin, beratBadan, jamBangun, jamTidur);
  }

  Future<Pengguna?> getPenggunaById(int id) async {
    return await _repository.getPenggunaById(id);
  }
}
