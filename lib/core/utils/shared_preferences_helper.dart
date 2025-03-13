import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _userIdKey = 'user_id';

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
}
