import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keySessionData = 'session_data';

  static Future<void> saveSession(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySessionData, id);
  }

  static Future<int?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySessionData);
  }
}
