// import '../../data/models/pengguna_model.dart';
import '../../data/repositories/pengguna_repository.dart';

class PenggunaController {
  final PenggunaRepository _repository = PenggunaRepository();

  // Mengecek apakah pengguna sudah terdaftar
  Future<bool> cekPenggunaTerdaftar() async {
    return await _repository.isPenggunaTerdaftar();
  }

  // Menambah pengguna dan profil pengguna pada halaman registrasi
  Future<int> tambahPenggunaDanProfil(String nama, String jenisKelamin,
      double beratBadan, String jamBangun, String jamTidur) async {
    return await _repository.tambahPenggunaDanProfil(
        nama, jenisKelamin, beratBadan, jamBangun, jamTidur);
  }

  // Mengambil data pengguna berdasarkan ID
  Future<Map<String, dynamic>> getPenggunaById(int id) async {
    try {
      return await _repository.getPenggunaById(id);
    } catch (e) {
      print("Error saat mengambil data pengguna: $e");
      return {};  // Mengembalikan map kosong jika terjadi error
    }
  }
}
