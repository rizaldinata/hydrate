import 'package:flutter/material.dart';

class RegistrationController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fungsi ini tidak melakukan async, hanya validasi.
  // Ia mengembalikan String error jika validasi gagal, dan null jika berhasil.
  String? validateInputs(String email, String password, String confirmPassword) {
    _setLoading(true);

    final bool isEmailValid =
        RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);

    if (!isEmailValid) {
      _setLoading(false);
      return "Masukkan email yang valid";
    }
    if (password.length < 6) {
      _setLoading(false);
      return "Password minimal harus 6 karakter.";
    }
    if (password != confirmPassword) {
      _setLoading(false);
      return "Konfirmasi password tidak cocok";
    }

    _setLoading(false);
    return null; // Mengembalikan null menandakan semua validasi lolos
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}