import 'package:flutter/material.dart'; 
import '../../data/models/target_hidrasi_model.dart';
import '../../data/repositories/target_hidrasi_repository.dart';
import 'package:intl/intl.dart';

class TargetHidrasiController extends ChangeNotifier { 
  final TargetHidrasiRepository _repository = TargetHidrasiRepository();

  double _currentDailyTargetMl = 0.0;
  bool _isLoadingTarget = false;
  TargetHidrasi? _currentTargetHidrasiObject;

  double get currentDailyTargetMl => _currentDailyTargetMl;
  bool get isLoadingTarget => _isLoadingTarget;
  TargetHidrasi? get currentTargetHidrasiObject => _currentTargetHidrasiObject;

  Future<void> initializeOrRefreshDailyTarget(int idPengguna, {bool isProfileChangeTrigger = false}) async {
    // Cek jika sedang loading dan bukan dipicu oleh perubahan profil (untuk menghindari re-entry yang tidak perlu dari sumber lain)
    if (_isLoadingTarget && !isProfileChangeTrigger) {
      print("[TargetHidrasiController] Sedang loading dan bukan dari profile change, initializeOrRefreshDailyTarget diabaikan untuk userId: $idPengguna.");
      return;
    }

    print("[TargetHidrasiController] initializeOrRefreshDailyTarget dipanggil untuk userId: $idPengguna, isProfileChangeTrigger: $isProfileChangeTrigger. Jam: ${DateTime.now()}");
    _isLoadingTarget = true;
    notifyListeners(); // Beritahu UI bahwa loading target dimulai

    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));

    try {
      // Panggil getTargetHidrasiHarian dari repository.
      // Fungsi ini di repository Anda sudah cerdas.
      final Map<String, dynamic>? targetDataMap = await _repository.getTargetHidrasiHarian(idPengguna, today);

      if (targetDataMap != null && targetDataMap['target_hidrasi'] != null) {
        double newTarget = (targetDataMap['target_hidrasi'] as num).toDouble();

        // Jika target dari repo tidak valid (0 atau negatif), hitung ulang menggunakan fallback dari repo
        if (newTarget <= 0) {
          print("[TargetHidrasiController] Target dari repo tidak valid ($newTarget) untuk $today. Menggunakan fallback kalkulasi dari repo.");
          // GUNAKAN NAMA METODE YANG BENAR DARI REPOSITORY ANDA
          newTarget = await _repository.fallbackCalculateTarget(idPengguna); 
        }
        _currentDailyTargetMl = newTarget;
        
        // Buat objek TargetHidrasi dari map yang dikembalikan repository
        Map<String, dynamic> completeMapForModel = {
          'id': targetDataMap['id_target_hidrasi'] ?? targetDataMap['id'], // Cek nama kolom ID di tabel Anda
          'fk_id_pengguna': idPengguna,
          'tanggal_hidrasi': today,
          'target_hidrasi': _currentDailyTargetMl,
          'total_hidrasi_harian': targetDataMap['total_hidrasi_harian'] ?? 0.0,
          // Hitung persentase menggunakan metode dari repository
          'persentase_hidrasi': _repository.internalCalculatePercentage(
            targetDataMap['total_hidrasi_harian']?.toDouble() ?? 0.0, 
            _currentDailyTargetMl
        ),
        };
        _currentTargetHidrasiObject = TargetHidrasi.fromMap(completeMapForModel);
        print("[TargetHidrasiController] Target harian di-refresh/diinisialisasi untuk $today: $_currentDailyTargetMl ml. Object: $_currentTargetHidrasiObject");
      } else {
        print("[TargetHidrasiController] Gagal mendapatkan target dari repo untuk $today (null atau target_hidrasi null). Mencoba fallback kalkulasi.");
        // Gunakan metode publik yang memanggil _calculateTargetHidrasi di repo
        _currentDailyTargetMl = await _repository.fallbackCalculateTarget(idPengguna); 
         _currentTargetHidrasiObject = TargetHidrasi(
            id: null,
            fkIdPengguna: idPengguna,
            targetHidrasi: _currentDailyTargetMl,
            tanggalHidrasi: today,
            totalHidrasiHarian: 0.0,
            persentaseHidrasi: 0.0 
        );
        print("[TargetHidrasiController] Fallback target: $_currentDailyTargetMl ml. Object: $_currentTargetHidrasiObject");
        // Pertimbangkan untuk menyimpan target fallback ini ke DB jika belum ada entri untuk hari ini
        // await _repository.createTargetHidrasi(idPengguna, _currentDailyTargetMl, today, 0.0);
      }
    } catch (e) {
      print("[TargetHidrasiController] Error saat initializeOrRefreshDailyTarget: $e");
      _currentDailyTargetMl = 2000.0; // Nilai aman jika terjadi error parah
      _currentTargetHidrasiObject = null;
    } finally {
      _isLoadingTarget = false;
      print("[TargetHidrasiController] initializeOrRefreshDailyTarget selesai. _isLoadingTarget: $_isLoadingTarget. Jam: ${DateTime.now()}");
      notifyListeners();
    }
  }

  Future<void> forceRecalculateAndUpdateTargetAfterProfileChange(int userId) async {
    print("[TargetHidrasiController] Memulai forceRecalculateAndUpdateTargetAfterProfileChange untuk userId: $userId. Jam: ${DateTime.now()}");
    
    _isLoadingTarget = true;
    notifyListeners(); 

    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    bool updateSuccessInRepo = false;
    try {
      updateSuccessInRepo = await _repository.updateTargetHidrasiValue(userId, today);
      
      if (updateSuccessInRepo) {
        print("[TargetHidrasiController] updateTargetHidrasiValue di repo berhasil.");
      } else {
        print("[TargetHidrasiController] updateTargetHidrasiValue di repo GAGAL. Target mungkin tidak terupdate di DB.");
      }
      await initializeOrRefreshDailyTarget(userId, isProfileChangeTrigger: true); 

    } catch (e) {
      print("[TargetHidrasiController] Error saat forceRecalculate: $e");
      await initializeOrRefreshDailyTarget(userId, isProfileChangeTrigger: true);
    } finally {
      if (_isLoadingTarget) { 
        _isLoadingTarget = false;
        print("[TargetHidrasiController] forceRecalculate (finally block) selesai. _isLoadingTarget: $_isLoadingTarget. Jam: ${DateTime.now()}");
        notifyListeners();
      }
    }
  }

  Future<double> getPresentasiHidrasiHarian(int idPengguna, String tanggal) async {
    return await _repository.getPresentasiHidrasiHarian(idPengguna, tanggal);
  }

  Future<bool> checkTargetHidrasiExists(int idPengguna) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    return await _repository.checkTargetHidrasiExists(idPengguna, today);
  }

  Future<int> createTargetHidrasi(
    int idPengguna,
    double targetHidrasiInput, // Ganti nama agar tidak bentrok dengan variabel kelas
    {double initialIntake = 0.0}
  ) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    final result = await _repository.createTargetHidrasi(
      idPengguna,
      targetHidrasiInput, 
      today,
      initialIntake
    );
    if (result > 0) {
      await getTargetHidrasiHarianMap(idPengguna); 
      notifyListeners();
    }
    return result;
  }

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
      await initializeOrRefreshDailyTarget(idPengguna); 
    }
    return success;
  }

  Future<double> getTotalHidrasiHariIni(int idPengguna) async {
    return await _repository.getTotalHidrasiHariIni(idPengguna);
  }

  Future<Map<String, dynamic>?> getTargetHidrasiHarianMap(int idPengguna) async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours: 7)));
    return await _repository.getTargetHidrasiHarian(idPengguna, today); 
  }

  Future<TargetHidrasi?> getTargetHidrasiByTanggal(int idPengguna, DateTime tanggal) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(tanggal);
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(Duration(hours:7)));
    
    if (formattedDate == today && _currentTargetHidrasiObject != null && _currentTargetHidrasiObject!.tanggalHidrasi == formattedDate) {
        print("[TargetHidrasiController] Mengembalikan _currentTargetHidrasiObject dari cache untuk $formattedDate");
        return _currentTargetHidrasiObject;
    }
    print("[TargetHidrasiController] Mengambil target dari repo untuk $formattedDate");
    return await _repository.getTargetHidrasi(idPengguna, formattedDate); 
  }
  Future<void> kurangiHidrasi(int idPengguna, double jumlahHidrasi) async {
    final double totalSaatIni = await _repository.getTotalHidrasiHariIni(idPengguna);
    final double totalBaru = totalSaatIni - jumlahHidrasi;
    await updateTotalHidrasi(idPengguna, totalBaru);
  }
}