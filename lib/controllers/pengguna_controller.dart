import 'package:hydrate/models/profil_pengguna_model.dart';
import '../models/pengguna_model.dart';
import '../data/repositories/pengguna_repository.dart';

class PenggunaController {
  final PenggunaRepository _repository = PenggunaRepository();

  // cek sudah pernah mendaftar atau belum
  Future<bool> cekPenggunaTerdaftar() async {
    return await _repository.isPenggunaTerdaftar();
  }

  // tambah pengguna dan profil pengguna pada halaman registrasi
  Future<int> tambahPenggunaDanProfil(String nama, String jenisKelamin,
      double beratBadan, String jamBangun, String jamTidur) async {
    return await _repository.tambahPenggunaDanProfil(
        nama, jenisKelamin, beratBadan, jamBangun, jamTidur);
  }

  // ambil semua data pengguna (kek e nanti ngga kepake)
  Future<List<Pengguna>> getPengguna() async {
    return await _repository.getPengguna();
  }

  // dalam ProfilPenggunaController
Future<int> editProfilPengguna(ProfilPengguna profil) async {
  return await _repository.editProfilPengguna(profil);
}
  
}
