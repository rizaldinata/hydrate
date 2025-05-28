import 'package:flutter/material.dart'; // Ditambahkan untuk ChangeNotifier (jika belum ada)
import 'package:hydrate/presentation/controllers/target_hidrasi_controller.dart';
import 'package:intl/intl.dart';
import '../../data/models/riwayat_hidrasi_model.dart';
import '../../data/repositories/riwayat_hidrasi_repository.dart';
// Import HydrationStatsController jika Anda ingin memanggilnya langsung.
// Namun, akan lebih baik jika pemanggilan dilakukan melalui mekanisme event atau
// jika TargetHidrasiController yang bertanggung jawab penuh setelah total berubah.
// Untuk modifikasi minimal, kita akan mengandalkan TargetHidrasiController.

// Jika controller ini belum extends ChangeNotifier dan Anda ingin UI langsung
// merespons perubahan daftar riwayat, tambahkan `extends ChangeNotifier`.
// Jika tidak, Anda bisa mengabaikannya.
class RiwayatHidrasiController extends ChangeNotifier { // Tambahkan 'extends ChangeNotifier' jika perlu
  final RiwayatHidrasiRepository _repository = RiwayatHidrasiRepository();

  // Daftar riwayat (opsional, jika UI ingin listen ke controller ini)
  List<RiwayatHidrasi> _riwayatHarian = [];
  List<RiwayatHidrasi> get riwayatHarian => _riwayatHarian;

  // tambah hidrasi dan tambah riwayat hidrasi
  Future<int> tambahRiwayatHidrasi({
    required int fkIdPengguna,
    required double jumlahHidrasi,
    required TargetHidrasiController targetController,
  }) async {
    final result = await _repository.tambahRiwayatHidrasi(
      fkIdPengguna: fkIdPengguna,
      jumlahHidrasi: jumlahHidrasi,
    );

    if (result > 0) {
      // Setelah berhasil menambah riwayat, update total hidrasi harian di tabel target_hidrasi
      // 1. Dapatkan total hidrasi terbaru untuk hari ini dari tabel riwayat_hidrasi
      //    (Metode getTotalHidrasiHariIni di controller ini sudah melakukannya)
      final double newTotalHidrasiHariIni = await getTotalHidrasiHariIni(fkIdPengguna);

      // 2. Panggil metode di TargetHidrasiController untuk mengupdate tabel target_hidrasi
      await targetController.updateTotalHidrasi(fkIdPengguna, newTotalHidrasiHariIni);
      
      // Muat ulang daftar riwayat untuk UI (jika UI listen ke controller ini)
      await getRiwayatHidrasiHariIni(fkIdPengguna); // Ini akan mengisi _riwayatHarian
      notifyListeners(); // Memberitahu listener bahwa data telah berubah
    }
    return result;
  }

  // Fungsi untuk mengambil riwayat hidrasi berdasarkan tanggal hari ini
  Future<List<RiwayatHidrasi>> getRiwayatHidrasiHariIni(int idPengguna) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    _riwayatHarian = await _repository.getRiwayatHidrasiByTanggal(idPengguna, today);
    notifyListeners(); // Jika UI listen ke perubahan daftar riwayat
    return _riwayatHarian;
  }

  // Fungsi untuk mengambil riwayat hidrasi berdasarkan tanggal tertentu
  Future<List<RiwayatHidrasi>> getRiwayatHidrasiByTanggal(int idPengguna, DateTime tanggal) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(tanggal);
    // Anda mungkin ingin menyimpan hasil ini ke state jika diperlukan
    return await _repository.getRiwayatHidrasiByTanggal(idPengguna, formattedDate);
  }

  // Fungsi untuk menghitung total hidrasi pada hari ini dari tabel riwayat_hidrasi
  // Ini berguna untuk mendapatkan total terbaru setelah penambahan sebelum update ke target_hidrasi
  Future<double> getTotalHidrasiHariIni(int idPengguna) async {
    // Gunakan zona waktu WIB secara konsisten
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    final List<RiwayatHidrasi> riwayatHariIni = await _repository.getRiwayatHidrasiByTanggal(idPengguna, today);
    
    double total = 0.0;
    for (var riwayat in riwayatHariIni) {
      total += riwayat.jumlahHidrasi;
    }
    
    return total;
  }

  // tampilin semua riwayat hidrasi
  Future<List<RiwayatHidrasi>> getRiwayatHidrasi(int idPengguna) async {
    // Anda mungkin ingin menyimpan hasil ini ke state jika diperlukan
    return await _repository.getRiwayatHidrasi(idPengguna);
  }

  // Hapus Riwayat Hidrasi
  Future<void> hapusRiwayatDanKurangiTarget({
    required int idRiwayat,
    required int idPengguna,
    required String tanggalHidrasi, // Mungkin berguna untuk validasi atau logging
    required TargetHidrasiController targetController,
  }) async {
    final jumlah = await _repository.hapusRiwayatBerdasarkanId(idRiwayat);
    if (jumlah != null) {
      print('Menghapus riwayat hidrasi dengan ID: $idRiwayat');
      // Metode kurangiHidrasi di TargetHidrasiController sudah benar karena memanggil
      // updateTotalHidrasi, yang mana di repository-nya sudah menghitung ulang persentase.
      await targetController.kurangiHidrasi(idPengguna, jumlah);
      
      // Muat ulang daftar riwayat untuk UI (jika UI listen ke controller ini)
      await getRiwayatHidrasiHariIni(idPengguna);
      notifyListeners();
    }
  }

  // Function Sort Riwayat
  List<RiwayatHidrasi> sortRiwayatByWaktuDescending(List<RiwayatHidrasi> list) {
    list.sort((a, b) {
      // Asumsikan waktuHidrasi adalah String yang valid atau nullable
      final timeA = timeToSeconds(a.waktuHidrasi); // Jika waktuHidrasi non-nullable di model
      final timeB = timeToSeconds(b.waktuHidrasi); // Jika waktuHidrasi non-nullable di model
      return timeB.compareTo(timeA); // Descending order
    });
    return list;
  }

  // Function Mengubah waktu ke second
  int timeToSeconds(String time) { // Jika waktuHidrasi non-nullable di model
    final parts = time.split(':');
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = (parts.length > 2) ? int.tryParse(parts[2]) ?? 0 : 0;
    return hours * 3600 + minutes * 60 + seconds;
  }
}