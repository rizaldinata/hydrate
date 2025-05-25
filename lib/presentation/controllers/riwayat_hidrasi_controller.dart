import 'package:hydrate/data/repositories/hydration/riwayat_hidrasi_repository.dart';
import 'package:hydrate/data/repositories/hydration/target_hidrasi_repository.dart';
import 'package:intl/intl.dart';
import '../../data/models/riwayat_hidrasi_model.dart';
import 'package:hydrate/locator.dart';

class RiwayatHidrasiController {
  final RiwayatHidrasiRepository _repository = locator<RiwayatHidrasiRepository>();
  final TargetHidrasiRepository _targetRepo = locator<TargetHidrasiRepository>();

  // tambah hidrasi dan tambah riwayat hidrasi
  Future<void> tambahHidrasi(int idPengguna, double jumlah) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = DateFormat('HH:mm:ss').format(DateTime.now());

    await _repository.addRiwayatHidrasi(
      localPenggunaId: idPengguna,
      jumlah: jumlah,
      tanggal: today,
      waktu: now,
    );
    // Setelah menambah riwayat, update juga total harian di target
    final totalHarian = await getTotalHidrasiHariIni(idPengguna);
    await _targetRepo.updateTotalHidrasi(idPengguna, today, totalHarian);
  }

  // Fungsi untuk mengambil riwayat hidrasi berdasarkan tanggal hari ini
  Future<List<RiwayatHidrasi>> getRiwayatHidrasiHariIni(int idPengguna) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Panggil metode baru yang sudah kita buat di repository
    final maps = await _repository.getLocalRiwayatHidrasiByTanggal(idPengguna, today);
    return maps.map((map) => RiwayatHidrasi.fromMap(map)).toList();
  }

  // Fungsi untuk mengambil riwayat hidrasi berdasarkan tanggal tertentu
  Future<List<RiwayatHidrasi>> getRiwayatHidrasiByTanggal(int idPengguna, DateTime tanggal) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(tanggal);
    final maps = await _repository.getLocalRiwayatHidrasiByTanggal(idPengguna, formattedDate);
    return maps.map((map) => RiwayatHidrasi.fromMap(map)).toList();
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
  Future<List<RiwayatHidrasi>> getAllRiwayatHidrasi(int idPengguna) async {
    // Gunakan nama metode yang benar
    final maps = await _repository.getAllLocalRiwayatHidrasi(idPengguna);
    return maps.map((map) => RiwayatHidrasi.fromMap(map)).toList();
  }

  // Hapus Riwayat Hidrasi
  Future<void> hapusRiwayatDanUpdateTotal({
    required String riwayatSyncId, // Gunakan sync_id, bukan idRiwayat
    required int idPengguna,
    required String tanggalHidrasi, // Tanggal dibutuhkan untuk update total
  }) async {
    try {
      // Panggil metode soft delete yang benar
      final bool berhasilHapus = await _repository.softDeleteRiwayatHidrasi(riwayatSyncId);

      if (berhasilHapus) {
        print('Riwayat hidrasi dengan sync_id: $riwayatSyncId berhasil di-soft-delete.');
        // Hitung ulang total hidrasi untuk hari itu
        final double totalBaru = await getTotalHidrasiHariIni(idPengguna);
        // Update total hidrasi di target repository
        await _targetRepo.updateTotalHidrasi(idPengguna, tanggalHidrasi, totalBaru);
      }
    } catch (e) {
      print("Error saat menghapus riwayat dan mengupdate total: $e");
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