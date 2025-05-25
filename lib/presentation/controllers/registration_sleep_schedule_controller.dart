import 'package:flutter/material.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/locator.dart';

class RegistrationSleepScheduleController with ChangeNotifier {
  final PenggunaRepository _penggunaRepository = locator<PenggunaRepository>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> completeRegistration({
    required String email,
    required String password,
    required String name,
    required String gender,
    required double weight,
    required String wakeUpTime,
    required String sleepTime,
  }) async {
    _setLoading(true);
    _clearError();

    if (wakeUpTime.isEmpty || sleepTime.isEmpty) {
      _errorMessage = "Jam bangun dan jam tidur harus diisi.";
      _setLoading(false);
      return false;
    }

    // Kumpulkan data profil
    Map<String, dynamic> dataProfil = {
      'jenis_kelamin': gender,
      'berat_badan': weight,
      'jam_bangun': wakeUpTime,
      'jam_tidur': sleepTime,
    };

    try {
      // Panggil metode dari PenggunaRepository untuk registrasi lengkap
      bool success = await _penggunaRepository.registerAndSetupUser(
        email: email,
        password: password,
        namaPengguna: name,
        dataProfil: dataProfil,
      );
      
      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    // Tidak perlu notifyListeners agar error tidak hilang tiba-tiba
  }
}