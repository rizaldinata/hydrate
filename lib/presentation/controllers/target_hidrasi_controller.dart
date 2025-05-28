import 'package:flutter/material.dart'; // Ditambahkan untuk ChangeNotifier
import '../../data/models/target_hidrasi_model.dart';
import '../../data/repositories/target_hidrasi_repository.dart';
import 'package:intl/intl.dart';
// Import HydrationStatsController jika Anda ingin memanggil update statistik dari sini
// import 'package:hydrate/presentation/controllers/hydration_stats_controller.dart';
// import 'package:hydrate/core/utils/session_manager.dart';


// Jika controller ini belum extends ChangeNotifier dan Anda ingin UI langsung
// merespons perubahan target, tambahkan `extends ChangeNotifier`.
class TargetHidrasiController extends ChangeNotifier { // Tambahkan 'extends ChangeNotifier' jika perlu
  final TargetHidrasiRepository _repository = TargetHidrasiRepository();

  // State untuk menyimpan target harian saat ini (opsional, jika UI listen ke controller ini)
  TargetHidrasi? _currentTargetHarian;
  TargetHidrasi? get currentTargetHarian => _currentTargetHarian;

  // Method untuk mendapatkan presentasi harian
  Future<double> getPresentasiHidrasiHarian(int idPengguna, String tanggal) async {
    return await _repository.getPresentasiHidrasiHarian(idPengguna, tanggal);
  }

  // Memeriksa apakah target hidrasi untuk hari ini sudah ada
  Future<bool> checkTargetHidrasiExists(int idPengguna) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    return await _repository.checkTargetHidrasiExists(idPengguna, today);
  }

  // Membuat target hidrasi baru
  Future<int> createTargetHidrasi(
    int idPengguna,
    double targetHidrasi, // Bisa 0.0 jika ingin dihitung otomatis oleh repository
    {double initialIntake = 0.0}
  ) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    final result = await _repository.createTargetHidrasi(
      idPengguna,
      targetHidrasi, // Repository akan menghitung jika ini <= 0
      today,
      initialIntake
    );
    if (result > 0) {
      await getTargetHidrasiHarian(idPengguna); // Muat ulang state target harian
      notifyListeners();
    }
    return result;
  }

  // Mengupdate total hidrasi harian di tabel target_hidrasi
  // Metode ini sudah ada dan dipanggil oleh RiwayatHidrasiController
  Future<bool> updateTotalHidrasi(
    int idPengguna,
    double totalHidrasi
  ) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    final success = await _repository.updateTotalHidrasi(
      idPengguna,
      today,
      totalHidrasi
    );
    if (success) {
      await getTargetHidrasiHarian(idPengguna); // Muat ulang state target harian
      notifyListeners();
    }
    return success;
  }

  // Mendapatkan total hidrasi hari ini dari tabel target_hidrasi
  Future<double> getTotalHidrasiHariIni(int idPengguna) async {
    // Metode ini di repository sudah mengembalikan total_hidrasi_harian
    return await _repository.getTotalHidrasiHariIni(idPengguna);
  }

  // Mendapatkan target hidrasi harian (Map)
  Future<Map<String, dynamic>?> getTargetHidrasiHarian(int idPengguna) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    final Map<String, dynamic>? targetData = await _repository.getTargetHidrasiHarian(idPengguna, today);
    if (targetData != null) {
      _currentTargetHarian = TargetHidrasi.fromMap({
        'id': null, // ID mungkin tidak selalu ada atau relevan untuk tampilan ini
        'fk_id_pengguna': idPengguna,
        'tanggal_hidrasi': today,
        ...targetData,
      });
      notifyListeners();
    }
    return targetData;
  }

  // Mendapatkan target hidrasi untuk tanggal tertentu (Objek TargetHidrasi)
  Future<TargetHidrasi?> getTargetHidrasiByTanggal(int idPengguna, DateTime tanggal) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(tanggal);
    // Anda mungkin ingin menyimpan hasil ini ke state jika diperlukan
    return await _repository.getTargetHidrasi(idPengguna, formattedDate);
  }

  // Mengurangi total hidrasi harian di tabel target_hidrasi
  Future<void> kurangiHidrasi(int idPengguna, double jumlahHidrasi) async {
    final double totalSaatIni = await getTotalHidrasiHariIni(idPengguna);
    final double totalBaru = totalSaatIni - jumlahHidrasi;
    await updateTotalHidrasi(idPengguna, totalBaru);
    // updateTotalHidrasi sudah memanggil notifyListeners
  }

  /// **TAMBAHAN BARU:**
  /// Metode untuk memicu perhitungan ulang dan pembaruan target hidrasi harian
  /// setelah ada perubahan pada profil pengguna (misalnya berat badan).
  Future<bool> recalculateAndUpdateDailyTargetAfterProfileChange(int userId) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    // Panggil metode di repository yang akan menghitung ulang target berdasarkan
    // data profil terbaru dan mengupdate entri untuk hari ini.
    final success = await _repository.updateTargetHidrasiValue(userId, today);
    if (success) {
      await getTargetHidrasiHarian(userId); // Muat ulang state target harian
      notifyListeners();
      // Anda mungkin juga ingin memicu pembaruan di HydrationStatsController jika ada
      // HydrationStatsController? statsController = ... (dapatkan dari Provider atau injeksi);
      // await statsController?.triggerDailyStatsUpdateAndRefresh();
    }
    return success;
  }
}