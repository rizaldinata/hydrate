import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';

class daftarPenggunaController {
  final PenggunaRepository penggunaRepository;

  daftarPenggunaController({required this.penggunaRepository});

  Future<bool> register(String nama, String jenisKelamin, double beratBadan,
      String jamBangun, String jamTidur) async {
    int? userId = await penggunaRepository.tambahPenggunaDanProfil(
        nama, jenisKelamin, beratBadan, jamBangun, jamTidur);

    if (userId != null) {
      // Simpan sesi pengguna setelah berhasil mendaftar
      await SessionManager().saveUserId(userId);
      print("User berhasil daftar dan login dengan ID: $userId");
      return true;
    } else {
      print("Pendaftaran gagal.");
      return false;
    }
  }
}
