import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static const String _notificationIntervalKey = 'notification_interval_seconds';
  static const int defaultNotificationIntervalSeconds = 65;

  Future<int> getNotificationInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notificationIntervalKey) ?? defaultNotificationIntervalSeconds;
  }

  Future<void> setNotificationInterval(int intervalInSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notificationIntervalKey, intervalInSeconds);
  }
}