import 'package:flutter/material.dart';
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/locator.dart';

class LoginController with ChangeNotifier {
  // 1. Langsung ambil repository dari locator. Tidak perlu constructor lagi.
  final PenggunaRepository _penggunaRepository = locator<PenggunaRepository>();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Fungsi utama untuk melakukan login (logikanya sudah benar, tidak perlu diubah)
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _penggunaRepository.signInWithEmailPassword(email, password);
      _setLoading(false);
      return true; // Login berhasil
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false; // Login gagal
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    // Tidak perlu notifyListeners di sini agar UI tidak re-render tanpa alasan
  }
}