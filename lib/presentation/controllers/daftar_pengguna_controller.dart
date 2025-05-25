import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/locator.dart';

// 4. Nama kelas menggunakan UpperCamelCase
class DaftarPenggunaController {
  
  // 1. Langsung ambil PenggunaRepository dari locator. Lebih sederhana!
  final PenggunaRepository _penggunaRepository = locator<PenggunaRepository>();

  Future<bool> register(String nama, String jenisKelamin, double beratBadan,
      String jamBangun, String jamTidur) async {
    
    // 3. Gunakan try-catch untuk penanganan error yang lebih aman
    try {
      // Panggil metode dari repository.
      // Di arsitektur baru, metode ini lebih deskriptif: tambahPenggunaDanProfilLokal
      final int userId = await _penggunaRepository.tambahPenggunaDanProfilLokal(
          nama, jenisKelamin, beratBadan, jamBangun, jamTidur);

      // 2. Logika SessionManager sudah ada di dalam repository, jadi HAPUS dari sini.

      // 3. Pengecekan hasil yang benar (ID harus lebih besar dari 0)
      if (userId > 0) {
        print("Controller: Pengguna lokal berhasil dibuat dengan ID: $userId");
        return true;
      } else {
        print("Controller: Repository melaporkan kegagalan (userId: $userId).");
        return false;
      }
    } catch (e) {
      // Menangkap error tak terduga dari lapisan bawahnya.
      print("Controller: Terjadi exception saat mendaftar: $e");
      return false;
    }
  }
}