import 'package:flutter/material.dart'; 
import 'package:hydrate/presentation/controllers/target_hidrasi_controller.dart';
import 'package:hydrate/presentation/widgets/statisticWidgets/statistic.dart';
import 'package:intl/intl.dart';
import '../../data/models/riwayat_hidrasi_model.dart';
import '../../data/repositories/riwayat_hidrasi_repository.dart';
class RiwayatHidrasiController extends ChangeNotifier { 
  final RiwayatHidrasiRepository _repository = RiwayatHidrasiRepository();

  // Variabel untuk menyimpan data riwayat hidrasi

  List<RiwayatHidrasi> _riwayatHarian = [];
  List<RiwayatHidrasi> get riwayatHarian => _riwayatHarian;

  // Variabel untuk menyimpan data statistik 

  List<Map<String, dynamic>> _statistikData = [];
  List<Map<String, dynamic>> get statistikData => _statistikData;

  bool _isLoadingStats = false;
  bool get isLoadingStats => _isLoadingStats;

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
      final double newTotalHidrasiHariIni = await getTotalHidrasiHariIni(fkIdPengguna);
      await targetController.updateTotalHidrasi(fkIdPengguna, newTotalHidrasiHariIni);
      
      await getRiwayatHidrasiHariIni(fkIdPengguna); 
      notifyListeners(); 
    }
    return result;
  }

  Future<List<RiwayatHidrasi>> getRiwayatHidrasiHariIni(int idPengguna) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    _riwayatHarian = await _repository.getRiwayatHidrasiByTanggal(idPengguna, today);
    notifyListeners(); 
    return _riwayatHarian;
  }

  Future<List<RiwayatHidrasi>> getRiwayatHidrasiByTanggal(int idPengguna, DateTime tanggal) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(tanggal);
    return await _repository.getRiwayatHidrasiByTanggal(idPengguna, formattedDate);
  }

  Future<double> getTotalHidrasiHariIni(int idPengguna) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    final List<RiwayatHidrasi> riwayatHariIni = await _repository.getRiwayatHidrasiByTanggal(idPengguna, today);
    
    double total = 0.0;
    for (var riwayat in riwayatHariIni) {
      total += riwayat.jumlahHidrasi;
    }
    
    return total;
  }

  Future<List<RiwayatHidrasi>> getRiwayatHidrasi(int idPengguna) async {
    return await _repository.getRiwayatHidrasi(idPengguna);
  }

  Future<void> hapusRiwayatDanKurangiTarget({
    required int idRiwayat,
    required int idPengguna,
    required String tanggalHidrasi,
    required TargetHidrasiController targetController,
  }) async {
    final jumlah = await _repository.hapusRiwayatBerdasarkanId(idRiwayat);
    if (jumlah != null) {
      await targetController.kurangiHidrasi(idPengguna, jumlah);
      
      await getRiwayatHidrasiHariIni(idPengguna);
      notifyListeners();
    }
  }

  List<RiwayatHidrasi> sortRiwayatByWaktuDescending(List<RiwayatHidrasi> list) {
    list.sort((a, b) {
      final timeA = timeToSeconds(a.waktuHidrasi); 
      final timeB = timeToSeconds(b.waktuHidrasi); 
      return timeB.compareTo(timeA); 
    });
    return list;
  }

  int timeToSeconds(String time) { 
    final parts = time.split(':');
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = (parts.length > 2) ? int.tryParse(parts[2]) ?? 0 : 0;
    return hours * 3600 + minutes * 60 + seconds;
  }

  Future<void> fetchStatistikData({
    required int userId,
    required StatisticPeriod periode,
    required DateTime referensiTanggal,
  }) async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      switch (periode) {
        case StatisticPeriod.weekly: 
          _statistikData = await _repository.getDailyHydrationForWeek(userId, referensiTanggal);
          break;
        case StatisticPeriod.monthly:
          _statistikData = await _repository.getWeeklyHydrationForMonth(userId, referensiTanggal.year, referensiTanggal.month);
          break;
        case StatisticPeriod.yearly:
          _statistikData = await _repository.getMonthlyHydrationForYear(userId, referensiTanggal.year);
          break;
      }
    } catch (_) {
      _statistikData = [];
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }
}