import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';

class DaftarPenggunaController {
  final PenggunaRepository penggunaRepository;

  DaftarPenggunaController({required this.penggunaRepository});

  Future<bool> register(String nama, String jenisKelamin, double beratBadan,
    String jamBangun, String jamTidur) async {
    int? userId = await penggunaRepository.tambahPenggunaDanProfil(nama, jenisKelamin, beratBadan, jamBangun, jamTidur);

    await SessionManager().saveUserId(userId);
    return true;
  }
}
