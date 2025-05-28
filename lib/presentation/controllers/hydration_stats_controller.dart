import 'package:flutter/material.dart';
import 'package:hydrate/data/models/hydration_stats_model.dart';
import 'package:hydrate/data/repositories/hydration_stats_repository.dart';
import 'package:hydrate/core/utils/session_manager.dart'; // Pastikan SessionManager ada

class HydrationStatsController extends ChangeNotifier {
  final HydrationStatsRepository _repository;

  HydrationStatsModel _stats = HydrationStatsModel.empty();
  bool _isLoading = false;
  String? _errorMessage;

  HydrationStatsModel get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  HydrationStatsController({HydrationStatsRepository? repository})
      : _repository = repository ?? HydrationStatsRepository();

  /// Memuat data statistik hidrasi untuk pengguna saat ini.
  Future<void> fetchHydrationStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final int? userId = await SessionManager().getUserId(); // Mengambil ID pengguna
      if (userId != null) {
        _stats = await _repository.getHydrationStatistics(userId);
        print("Statistik hidrasi dimuat untuk pengguna ID: $userId");
      } else {
        _stats = HydrationStatsModel.empty(); // Reset jika tidak ada user ID
        _errorMessage = "ID pengguna tidak ditemukan. Tidak dapat memuat statistik.";
        print(_errorMessage);
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat statistik hidrasi: $e';
      _stats = HydrationStatsModel.empty(); // Reset jika ada error
      print('Error di HydrationStatsController (fetchHydrationStats): $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Metode untuk memicu pembaruan statistik harian di `target_hidrasi`
  /// (yaitu total_hidrasi_harian dan persentase_hidrasi)
  /// dan kemudian memuat ulang statistik gabungan.
  /// Ini harus dipanggil setelah ada perubahan data hidrasi (tambah/hapus riwayat).
  Future<void> triggerDailyStatsUpdateAndRefresh() async {
    _isLoading = true;
    notifyListeners(); // Memberitahu UI bahwa proses dimulai

    try {
      final int? userId = await SessionManager().getUserId();
      if (userId != null) {
        // Panggil metode di HydrationStatsRepository untuk memastikan
        // total_hidrasi_harian dan persentase_hidrasi di tabel target_hidrasi diperbarui.
        // Diasumsikan zona waktu sudah dihandle di dalam repository atau DateTime.now() lokal sudah sesuai.
        // Untuk konsistensi dengan kode Anda, saya gunakan WIB.
        await _repository.updateDailyTargetAndCompletion(userId, DateTime.now().toUtc().add(Duration(hours:7)));
        
        // Setelah itu, fetch ulang statistik gabungan.
        await fetchHydrationStats();
      } else {
         _errorMessage = "ID pengguna tidak ditemukan. Tidak dapat memperbarui statistik.";
        print(_errorMessage);
      }
    } catch (e) {
      _errorMessage = 'Gagal memperbarui dan memuat ulang statistik: $e';
      print('Error di HydrationStatsController (triggerDailyStatsUpdateAndRefresh): $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners(); // Memberitahu UI bahwa proses selesai
    }
  }
}