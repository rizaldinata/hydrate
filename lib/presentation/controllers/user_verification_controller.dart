import 'package:hydrate/core/utils/session_manager.dart';
import 'package:hydrate/core/utils/hydration_calculator.dart';
import 'package:hydrate/data/repositories/target_hidrasi_repository.dart';
import 'package:hydrate/presentation/controllers/pengguna_controller.dart';
import 'package:intl/intl.dart';

class UserVerificationController {
  final PenggunaController _penggunaController = PenggunaController();
  final TargetHidrasiRepository _targetHidrasiRepository = TargetHidrasiRepository();
  late HydrationCalculator _hydrationCalculator;
  
  int? _idPengguna;
  String? _namaPengguna;
  double _target = 0;
  double _currentIntake = 0;
  bool _hasInitializedTarget = false;
  
  int? get idPengguna => _idPengguna;
  String? get namaPengguna => _namaPengguna;
  double get target => _target;
  double get currentIntake => _currentIntake;
  bool get isUserValid => _idPengguna != null && _namaPengguna != null;
  
  String get todayDate => DateFormat('yyyy-MM-dd')
      .format(DateTime.now().toUtc().add(const Duration(hours: 7)));

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

      _hydrationCalculator = HydrationCalculator(penggunaId: userId);
      
      _idPengguna = userId;
      _namaPengguna = pengguna.nama;

      await _initializeTarget();
      
      await _loadTodayIntake();

      return UserVerificationResult(
        success: true,
        userId: userId,
        userName: pengguna.nama,
        target: _target,
        currentIntake: _currentIntake,
      );

    } catch (_) {
      return UserVerificationResult(
        success: false,
        error: "Error loading user data",
      );
    }
  }

  Future<void> _initializeTarget() async {
    if (_hasInitializedTarget || _idPengguna == null) return;

    try {
      await _hydrationCalculator.initializeData(_idPengguna!);
      final targetHidrasi = _hydrationCalculator.calculateDailyWaterIntake() * 1000;

      _hasInitializedTarget = true;
      _target = targetHidrasi;

      await _checkAndCreateTodayTarget();

    } catch (e) {
      _hasInitializedTarget = false;
    }
  }

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
      } else {
        await _targetHidrasiRepository.updateTargetHidrasiValue(_idPengguna!, todayDate);

        final updatedTargetData = await _targetHidrasiRepository
            .getTargetHidrasiHarian(_idPengguna!, todayDate);

        if (updatedTargetData != null && (updatedTargetData['target_hidrasi'] ?? 0) > 0) {
          _target = updatedTargetData['target_hidrasi'];
        }
      }
    } catch (_) {
      try {
        if (_idPengguna != null) {
          await _hydrationCalculator.initializeData(_idPengguna!);
          final calculatedTarget = _hydrationCalculator.calculateDailyWaterIntake() * 1000;
          _target = calculatedTarget;
        }
      } catch (_) {}
    }
  }

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

      } else {
        _currentIntake = 0;
      }
    } catch (_) {}
  }

  Future<UserVerificationResult> refreshUserData() async {
    _hasInitializedTarget = false;
    return await loadAndVerifyUser();
  }

  void reset() {
    _idPengguna = null;
    _namaPengguna = null;
    _target = 0;
    _currentIntake = 0;
    _hasInitializedTarget = false;
  }

  double getIntakePercentage() {
    if (_target <= 0) return 0;
    final percentage = (_currentIntake / _target) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  bool isTargetAchieved() {
    return _target > 0 && _currentIntake >= _target;
  }
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