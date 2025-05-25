import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/locator.dart'; 
import 'package:hydrate/presentation/controllers/notifikasi_controller.dart'; 

class HomeScreenController with ChangeNotifier {
  final PenggunaRepository _penggunaRepository = locator<PenggunaRepository>();
  final SharedPreferences _prefs = locator<SharedPreferences>();
  final SessionManager _sessionManager = locator<SessionManager>();

  // State Variables
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _userName;
  String? get userName => _userName;

  double _targetIntake = 0.0;
  double get targetIntake => _targetIntake;

  double _currentIntake = 0.0;
  double get currentIntake => _currentIntake;

  double get progressPercentage => (_targetIntake > 0) ? min(100, (_currentIntake / _targetIntake) * 100) : 0.0;

  Duration _remainingTime = Duration.zero;
  Duration get remainingTime => _remainingTime;

  bool _isCountdownActive = false;
  bool get isCountdownActive => _isCountdownActive;

  bool _hasReachedTargetToday = false;
  bool get hasReachedTargetToday => _hasReachedTargetToday;

  // Timer constants and keys
  static const int _countdownDurationInSeconds = 5400; // 1.5 jam (sesuaikan)
  static const String _endTimeKey = 'countdown_end_time_v2';
  static const String _timerStartedKey = 'timer_has_started_v2';
  static const String _targetReachedKeyPrefix = 'target_reached_';

  Timer? _countdownTimer;
  int? _userId;
  int? get userId => _userId;
  late HydrationCalculator _hydrationCalculator;
  bool _isCalculatorInitialized = false; 
  String _todayDateString = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(const Duration(hours: 7)));
  

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _userId = await _sessionManager.getUserId();
    if (_userId == null) {
      _isLoading = false;
      // Mungkin ada error handling di sini jika user ID tidak ditemukan
      notifyListeners();
      return;
    }

    await _loadUserData();
    await _initializeOrUpdateTarget();
    await _loadTodayIntakeAndProgress();
    await _loadPersistedTimerState();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_userId == null) return;
    try {
      final pengguna = await _penggunaRepository.getPenggunaById(_userId!); // Asumsi metode ini ada
      if (pengguna != null) {
        _userName = pengguna.nama;
      }
    } catch (e) {
      print("HomeScreenController: Error loading user data: $e");
    }
  }

  Future<void> _initializeOrUpdateTarget() async {
    if (_userId == null) {
      print("HomeScreenController: User ID null, tidak bisa inisialisasi target.");
      _targetIntake = 2000.0; 
      _hydrationCalculator = HydrationCalculator(
        jenisKelaminInput: "Laki-laki", 
        beratBadanInput: 70.0,        
        jamBangunInputStr: "06:00",     
        jamTidurInputStr: "22:00"       
      );
      notifyListeners(); // Jika ada perubahan state yang perlu di-render
      return;
    };
    try {
      // 1. Ambil data profil pengguna dari PenggunaRepository
      final profilDataMap = await _penggunaRepository.getLocalUserProfile(_userId!);

      String jenisKelaminProfil;
      double beratBadanProfil;
      String jamBangunProfilStr;
      String jamTidurProfilStr;

      if (profilDataMap != null) {
        jenisKelaminProfil = profilDataMap['jenis_kelamin'] as String? ?? "Laki-laki";
        beratBadanProfil = (profilDataMap['berat_badan'] as num?)?.toDouble() ?? 70.0;
        jamBangunProfilStr = profilDataMap['jam_bangun'] as String? ?? "06:00";
        jamTidurProfilStr = profilDataMap['jam_tidur'] as String? ?? "22:00";
      } else {
        print("HomeScreenController: Profil tidak ditemukan untuk userId: $_userId. Menggunakan default.");
        jenisKelaminProfil = "Laki-laki";
        beratBadanProfil = 70.0;
        jamBangunProfilStr = "06:00";
        jamTidurProfilStr = "22:00";
      }

      // 2. Buat instance HydrationCalculator dengan data yang sudah diambil/default
      _hydrationCalculator = HydrationCalculator(
        jenisKelaminInput: jenisKelaminProfil,
        beratBadanInput: beratBadanProfil,
        jamBangunInputStr: jamBangunProfilStr,
        jamTidurInputStr: jamTidurProfilStr,
      );
    
      // 3. Hitung target menggunakan instance _hydrationCalculator yang baru
      double calculatedTarget = _hydrationCalculator.calculateDailyWaterIntake() * 1000; 
      
      // 4. Lanjutkan logika Anda untuk check, create, atau update target di database
      bool targetExists = await _penggunaRepository.checkTargetHidrasiExists(_userId!, _todayDateString);

      if (!targetExists) {
        await _penggunaRepository.createTargetHidrasi(_userId!, calculatedTarget, _todayDateString, 0.0);
        _targetIntake = calculatedTarget;
      } else {
        // Jika sudah ada, pastikan nilai target_hidrasi di DB adalah yang terbaru
        // Atau jika ingin selalu pakai hasil kalkulasi:
        await _penggunaRepository.updateTargetHidrasiValueIfDifferent(_userId!, _todayDateString, calculatedTarget);
        final dailyTargetData = await _penggunaRepository.getTargetHidrasiHarian(_userId!, _todayDateString);
        _targetIntake = dailyTargetData?['target_hidrasi'] ?? calculatedTarget;
      }
      print("HomeScreenController: Target diinisialisasi/diupdate menjadi: $_targetIntake mL");
    } catch (e) {
       print("HomeScreenController: Error initializing/updating target or calculator: $e");
      // Fallback jika gagal load dari DB
      _targetIntake = 2000.0; 
      if (!_isCalculatorInitialized) { 
      _hydrationCalculator = HydrationCalculator(
          jenisKelaminInput: "Laki-laki",
          beratBadanInput: 70.0,
          jamBangunInputStr: "06:00",
          jamTidurInputStr: "22:00"
      );
      _isCalculatorInitialized = true; 
      print("HomeScreenController: _hydrationCalculator diinisialisasi dengan default karena error.");
    } else {
       print("HomeScreenController: _hydrationCalculator sudah pernah diinisialisasi, tidak membuat ulang dengan default di catch.");
    }
    }
  }

  Future<void> _loadTodayIntakeAndProgress() async {
    if (_userId == null) return;
    try {
      final dailyTargetData = await _penggunaRepository.getTargetHidrasiHarian(_userId!, _todayDateString);
      if (dailyTargetData != null) {
        _currentIntake = dailyTargetData['total_hidrasi_harian'] ?? 0.0;
        _targetIntake = dailyTargetData['target_hidrasi'] ?? _targetIntake; // Pastikan target juga terupdate
      } else {
        // Jika belum ada record target, berarti intake juga 0
        _currentIntake = 0.0;
        // Pastikan target sudah diinisialisasi dari _initializeOrUpdateTarget
      }
      _checkIfTargetReachedToday();

    } catch (e) {
      print("HomeScreenController: Error loading today's intake: $e");
    }
  }
  
  Future<void> addWater(double amount) async {
    if (_userId == null) return;
    
    _currentIntake += amount;
    
    try {
      // Tambah riwayat dan update total di repository
      // PenggunaRepository harusnya sudah menangani sinkronisasi ke Firestore
      await _penggunaRepository.addRiwayatHidrasi(
          localPenggunaId: _userId!,
          jumlah: amount,
          tanggal: _todayDateString,
          waktu: DateFormat('HH:mm:ss').format(DateTime.now().toUtc().add(const Duration(hours: 7)))
      );
      // Metode updateTotalHidrasi di repository akan mengkalkulasi persentase juga
      await _penggunaRepository.updateTotalHidrasi(_userId!, _todayDateString, _currentIntake);

      // Reload data untuk memastikan konsistensi, atau update state secara manual
      final dailyTargetData = await _penggunaRepository.getTargetHidrasiHarian(_userId!, _todayDateString);
       if (dailyTargetData != null) {
        _currentIntake = dailyTargetData['total_hidrasi_harian'] ?? _currentIntake;
        _targetIntake = dailyTargetData['target_hidrasi'] ?? _targetIntake;
      }

    } catch (e) {
      print("HomeScreenController: Error adding water: $e");
      _currentIntake -= amount; // Rollback jika gagal
      // Set error message untuk ditampilkan di UI
    }
    
    _checkIfTargetReachedToday(isNewIntake: true);
    startReminderTimer(); // Mulai timer setelah minum
    notifyListeners();
  }

  void _checkIfTargetReachedToday({bool isNewIntake = false}) {
    bool currentlyReached = _currentIntake >= _targetIntake && _targetIntake > 0;
    String key = '$_targetReachedKeyPrefix$_todayDateString';

    if (isNewIntake && currentlyReached && !_hasReachedTargetToday) {
      _hasReachedTargetToday = true;
      _prefs.setBool(key, true); // Simpan status pencapaian harian
      // Mungkin ada event atau flag lain untuk memicu confetti di UI
    } else if (!isNewIntake) { // Saat load awal
      _hasReachedTargetToday = _prefs.getBool(key) ?? false;
      if (currentlyReached && !_hasReachedTargetToday) {
         // Jika target tercapai tapi belum ditandai (misal data disinkron dari device lain)
        _hasReachedTargetToday = true;
        _prefs.setBool(key, true);
      } else if (!currentlyReached && _hasReachedTargetToday) {
        // Jika hari baru, reset status
         _hasReachedTargetToday = false;
         _prefs.remove(key);
      }
    }
    // Jika target belum tercapai, pastikan _hasReachedTargetToday adalah false
    if (!currentlyReached) {
      _hasReachedTargetToday = false;
      // _prefs.remove(key); // Hapus jika ingin notifikasi muncul lagi jika intake berkurang
    }
  }


  // --- Timer Logic ---
  Future<void> _loadPersistedTimerState() async {
    final endTimeMillis = _prefs.getInt(_endTimeKey);
    final timerStarted = _prefs.getBool(_timerStartedKey) ?? false;

    if (!timerStarted) {
      _isCountdownActive = false;
      _remainingTime = Duration.zero;
      return;
    }

    if (endTimeMillis != null) {
      final DateTime endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      final now = DateTime.now();
      if (endTime.isAfter(now)) {
        _remainingTime = endTime.difference(now);
        _isCountdownActive = true;
        _runCountdownTimer();
      } else {
        _remainingTime = Duration.zero;
        _isCountdownActive = true; // Akan menampilkan "SAATNYA MINUM!" jika currentIntake > 0
        if (_currentIntake > 0) NotificationController.createNewNotification(); // Notifikasi jika sudah minum tapi timer habis
      }
    } else {
      // Tidak ada timer tersimpan, tapi user mungkin sudah minum hari ini
      _isCountdownActive = _currentIntake > 0;
      _remainingTime = Duration.zero;
    }
  }

  Future<void> _savePersistedTimerState() async {
    if (_isCountdownActive && _remainingTime > Duration.zero) {
      final DateTime endTime = DateTime.now().add(_remainingTime);
      await _prefs.setInt(_endTimeKey, endTime.millisecondsSinceEpoch);
      await _prefs.setBool(_timerStartedKey, true);
    } else {
      // Jika timer tidak aktif atau sudah habis, hapus endTime
      await _prefs.remove(_endTimeKey);
      // Jangan hapus _timerStartedKey jika ingin behavior "SAATNYA MINUM!" tetap ada
    }
  }

  void startReminderTimer() {
    _countdownTimer?.cancel();
    _remainingTime = const Duration(seconds: _countdownDurationInSeconds);
    _isCountdownActive = true;
    _savePersistedTimerState(); // Simpan state baru
    _runCountdownTimer();
    notifyListeners();
  }

  void _runCountdownTimer() {
    _countdownTimer?.cancel(); // Pastikan timer lama dihentikan
    if (!_isCountdownActive || _remainingTime == Duration.zero) {
      if (_isCountdownActive && _currentIntake > 0) { // Kondisi "SAATNYA MINUM!"
         NotificationController.createNewNotification();
      }
      notifyListeners(); // Update UI untuk menampilkan "SAATNYA MINUM!"
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > Duration.zero) {
        _remainingTime -= const Duration(seconds: 1);
      } else {
        timer.cancel();
        _isCountdownActive = true; // Tetap aktif untuk "SAATNYA MINUM!"
        if (_currentIntake > 0) NotificationController.createNewNotification();
        _savePersistedTimerState(); // Simpan bahwa timer sudah habis
      }
      notifyListeners();
    });
  }
  
  // Panggil ini saat app pause atau close
  void onAppPause() {
    _countdownTimer?.cancel();
    _savePersistedTimerState();
  }

  void refreshData() {
    _todayDateString = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc().add(const Duration(hours: 7)));
    initialize();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  
}