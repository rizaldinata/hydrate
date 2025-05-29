// lib/presentation/controllers/user_verification_controller.dart
import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/pengguna_controller.dart';
import 'package:intl/intl.dart';

class UserVerificationController {
  final PenggunaController _penggunaController = PenggunaController();
  final TargetHidrasiRepository _targetHidrasiRepository = TargetHidrasiRepository();
  late HydrationCalculator _hydrationCalculator;
  
  // User data
  int? _idPengguna;
  String? _namaPengguna;
  double _target = 0;
  double _currentIntake = 0;
  bool _hasInitializedTarget = false;
  
  // Getters
  int? get idPengguna => _idPengguna;
  String? get namaPengguna => _namaPengguna;
  double get target => _target;
  double get currentIntake => _currentIntake;
  bool get isUserValid => _idPengguna != null && _namaPengguna != null;
  
  String get todayDate => DateFormat('yyyy-MM-dd')
      .format(DateTime.now().toUtc().add(const Duration(hours: 7)));

  /// Memuat dan memverifikasi data user
  Future<UserVerificationResult> loadAndVerifyUser() async {
    try {
      final session = SessionManager();
      final userId = await session.getUserId();

      if (userId == null) {
        return UserVerificationResult(
          success: false,
          error: "UserId tidak ditemukan dalam session",
          shouldNavigateToLogin: true,
        );
      }

      final pengguna = await _penggunaController.getPenggunaById(userId);
      
      if (pengguna == null) {
        return UserVerificationResult(
          success: false,
          error: "Data pengguna tidak ditemukan untuk userId: $userId",
          shouldNavigateToLogin: true,
        );
      }

      // Initialize hydration calculator
      _hydrationCalculator = HydrationCalculator(penggunaId: userId);
      
      // Set user data
      _idPengguna = userId;
      _namaPengguna = pengguna.nama;

      // Initialize target
      await _initializeTarget();
      
      // Load today's intake
      await _loadTodayIntake();

      return UserVerificationResult(
        success: true,
        userId: userId,
        userName: pengguna.nama,
        target: _target,
        currentIntake: _currentIntake,
      );

    } catch (e) {
      print("Error loading user data: $e");
      return UserVerificationResult(
        success: false,
        error: "Error loading user data: $e",
      );
    }
  }

  /// Inisialisasi target hidrasi
  Future<void> _initializeTarget() async {
    if (_hasInitializedTarget || _idPengguna == null) return;

    try {
      await _hydrationCalculator.initializeData(_idPengguna!);
      final targetHidrasi = _hydrationCalculator.calculateDailyWaterIntake() * 1000;

      _hasInitializedTarget = true;
      _target = targetHidrasi;

      await _checkAndCreateTodayTarget();

      print("Target hidrasi diinisialisasi: $_target mL");
    } catch (e) {
      print("Error initializing target: $e");
      _hasInitializedTarget = false;
    }
  }

  /// Memeriksa dan membuat target hari ini jika belum ada
  Future<void> _checkAndCreateTodayTarget() async {
    if (_idPengguna == null) return;

    try {
      final targetExists = await _targetHidrasiRepository
          .checkTargetHidrasiExists(_idPengguna!, todayDate);

      if (!targetExists) {
        double currentCalculatedTarget = _target;
        if (currentCalculatedTarget <= 0) {
          await _hydrationCalculator.initializeData(_idPengguna!);
          currentCalculatedTarget = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
          _target = currentCalculatedTarget;
        }

        await _targetHidrasiRepository.createTargetHidrasi(
            _idPengguna!, currentCalculatedTarget, todayDate, 0.0);
        print("Target hidrasi baru dibuat untuk tanggal $todayDate: $currentCalculatedTarget mL");
      } else {
        await _targetHidrasiRepository.updateTargetHidrasiValue(_idPengguna!, todayDate);
        print("Target hidrasi untuk tanggal $todayDate sudah ada dan diperbarui jika perlu");

        final updatedTargetData = await _targetHidrasiRepository
            .getTargetHidrasiHarian(_idPengguna!, todayDate);

        if (updatedTargetData != null && (updatedTargetData['target_hidrasi'] ?? 0) > 0) {
          _target = updatedTargetData['target_hidrasi'];
          print("Target hidrasi dari DB: $_target mL");
        }
      }
    } catch (e) {
      print("Error saat memeriksa/membuat target hidrasi: $e");
      // Fallback: try to ensure target is set based on calculation
      try {
        if (_idPengguna != null) {
          await _hydrationCalculator.initializeData(_idPengguna!);
          final calculatedTarget = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
          _target = calculatedTarget;
          print("Target hidrasi (recovery): $_target mL");
        }
      } catch (e2) {
        print("Error saat menghitung target hidrasi (recovery): $e2");
      }
    }
  }

  /// Memuat intake hari ini
  Future<void> _loadTodayIntake() async {
    if (_idPengguna == null) return;

    try {
      if (_target <= 0) {
        await _initializeTarget();
        if (_target <= 0) return;
      }

      final targetHarian = await _targetHidrasiRepository
          .getTargetHidrasiHarian(_idPengguna!, todayDate);

      if (targetHarian != null) {
        double dbTargetHidrasi = targetHarian['target_hidrasi'] ?? 0.0;
        double totalHidrasi = targetHarian['total_hidrasi_harian'] ?? 0.0;

        _target = dbTargetHidrasi > 0 ? dbTargetHidrasi : _target;
        _currentIntake = totalHidrasi;

        print("Data hidrasi dimuat: $totalHidrasi mL dari target $_target mL");
      } else {
        print("Peringatan: Record target_hidrasi tidak ditemukan untuk hari ini setelah pengecekan.");
        _currentIntake = 0;
      }
    } catch (e) {
      print("Error saat memuat intake hari ini: $e");
    }
  }

  /// Refresh data user
  Future<UserVerificationResult> refreshUserData() async {
    _hasInitializedTarget = false;
    return await loadAndVerifyUser();
  }

  /// Reset controller state
  void reset() {
    _idPengguna = null;
    _namaPengguna = null;
    _target = 0;
    _currentIntake = 0;
    _hasInitializedTarget = false;
  }

  /// Get current intake percentage
  double getIntakePercentage() {
    if (_target <= 0) return 0;
    final percentage = (_currentIntake / _target) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  /// Check if target is achieved
  bool isTargetAchieved() {
    return _target > 0 && _currentIntake >= _target;
  }

  /// Get truncated name for display
  String getTruncatedName(int maxLength) {
    if (_namaPengguna == null) return "";
    if (_namaPengguna!.length <= maxLength) return _namaPengguna!;

    int lastSpace = _namaPengguna!.substring(0, maxLength).lastIndexOf(' ');
    if (lastSpace == -1 || lastSpace < maxLength - 5) {
      return "${_namaPengguna!.substring(0, maxLength - 3)}...";
    } else {
      return "${_namaPengguna!.substring(0, lastSpace)}...";
    }
  }
}

/// Result class untuk hasil verifikasi user
class UserVerificationResult {
  final bool success;
  final String? error;
  final int? userId;
  final String? userName;
  final double? target;
  final double? currentIntake;
  final bool shouldNavigateToLogin;

  UserVerificationResult({
    required this.success,
    this.error,
    this.userId,
    this.userName,
    this.target,
    this.currentIntake,
    this.shouldNavigateToLogin = false,
  });

  @override
  String toString() {
    return 'UserVerificationResult(success: $success, error: $error, userId: $userId, userName: $userName)';
  }
}