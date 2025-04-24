import 'package:hydrate/presentation/controllers/target_hidrasi_controller.dart';
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
    final formattedDate = DateFormat('yyyy-MM-dd').format(tanggal);
    return await _repository.getRiwayatHidrasiByTanggal(idPengguna, formattedDate);
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

  // Hapus Riwayat Hidrasi
  Future<void> hapusRiwayatDanKurangiTarget({
    required int idRiwayat,
    required int idPengguna,
    required String tanggalHidrasi,
    required TargetHidrasiController targetController,
  }) async {
    final jumlah = await _repository.hapusRiwayatBerdasarkanId(idRiwayat);
    if (jumlah != null) {
      print('Menghapus riwayat hidrasi dengan ID: $idRiwayat');
      await targetController.kurangiHidrasi(idPengguna, jumlah);
    }
  }

  // Function Sort Riwayat
  List<RiwayatHidrasi> sortRiwayatByWaktuDescending(List<RiwayatHidrasi> list) {
    list.sort((a, b) {
      final timeA = timeToSeconds(a.waktuHidrasi ?? "00:00");
      final timeB = timeToSeconds(b.waktuHidrasi ?? "00:00");
      return timeB.compareTo(timeA); // Descending order
    });
    return list;
  }

  // Function Mengubah waktu ke second
  int timeToSeconds(String time) {
    final parts = time.split(':');
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = (parts.length > 2) ? int.tryParse(parts[2]) ?? 0 : 0;
    return hours * 3600 + minutes * 60 + seconds;
  }
}