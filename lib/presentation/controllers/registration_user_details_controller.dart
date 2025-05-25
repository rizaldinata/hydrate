import 'package:flutter/material.dart';

class RegistrationUserDetailsController with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Validasi detail pengguna
  // Mengembalikan String error jika tidak valid, atau null jika valid.
  String? validateDetails(String name, String weightText) {
    _setLoading(true);

    if (name.isEmpty) {
      _setLoading(false);
      return "Nama pengguna tidak boleh kosong.";
    }
    if (name.length > 20) { // Sesuai maxCharacters Anda sebelumnya
        _setLoading(false);
        return "Nama pengguna maksimal 20 karakter.";
    }

    final double? weight = double.tryParse(weightText);
    if (weight == null) {
      _setLoading(false);
      return "Masukkan berat badan yang valid (angka).";
    }
    if (weight < 1 || weight > 300) {
      _setLoading(false);
      return "Berat badan harus antara 1 kg hingga 300 kg.";
    }

    _setLoading(false);
    return null; // Validasi berhasil
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}