import 'package:intl/intl.dart';
import '../../data/models/riwayat_hidrasi_model.dart';
import '../../data/repositories/riwayat_hidrasi_repository.dart';

class RiwayatHidrasiController {
  final RiwayatHidrasiRepository _repository = RiwayatHidrasiRepository();

  // tambah hidrasi dan tambah riwayat hidrasi
  Future<int> tambahRiwayatHidrasi({
    required int fkIdPengguna,
    required double jumlahHidrasi,
  }) async {
    return await _repository.tambahRiwayatHidrasi(
      fkIdPengguna: fkIdPengguna,
      jumlahHidrasi: jumlahHidrasi,
    );
  }

  // Fungsi untuk mengambil riwayat hidrasi berdasarkan tanggal hari ini
  Future<List<RiwayatHidrasi>> getRiwayatHidrasiHariIni(int idPengguna) async {
    // Gunakan zona waktu WIB
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    return await _repository.getRiwayatHidrasiByTanggal(idPengguna, today);
  }

  // Fungsi untuk mengambil riwayat hidrasi berdasarkan tanggal tertentu
  Future<List<RiwayatHidrasi>> getRiwayatHidrasiByTanggal(int idPengguna, DateTime tanggal) async {
    // Pastikan tanggal dalam zona waktu WIB
    final DateTime wibTanggal = tanggal.toUtc().add(Duration(hours: 7));
    final String formattedDate = DateFormat('yyyy-MM-dd').format(wibTanggal);
    print("[DEBUG Controller] Memuat data untuk tanggal: $formattedDate, userId: $idPengguna");
    
    final result = await _repository.getRiwayatHidrasiByTanggal(idPengguna, formattedDate);
    print("[DEBUG Controller] Jumlah data ditemukan: ${result.length}");
    return result;
  }

  // Fungsi untuk menghitung total hidrasi pada hari ini
  Future<double> getTotalHidrasiHariIni(int idPengguna) async {
    final List<RiwayatHidrasi> riwayatHariIni = await getRiwayatHidrasiHariIni(idPengguna);
    
    double total = 0.0;
    for (var riwayat in riwayatHariIni) {
      total += riwayat.jumlahHidrasi;
    }
    
    return total;
  }

  // tampilin semua riwayat hidrasi
  Future<List<RiwayatHidrasi>> getRiwayatHidrasi(int idPengguna) async {
    return await _repository.getRiwayatHidrasi(idPengguna);
  }
}