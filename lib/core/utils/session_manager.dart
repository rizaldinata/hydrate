import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUserId = "id";

  // Menyimpan ID pengguna ke SharedPreferences
  Future<void> saveUserId(int userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  // Mendapatkan ID pengguna dari SharedPreferences
  Future<int?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // Menghapus session (logout)
  Future<void> clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }
}
