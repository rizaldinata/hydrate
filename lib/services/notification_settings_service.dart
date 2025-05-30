import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class NotificationSettingsService {
  static const String _wakeUpHourKey = 'wake_up_hour';
  static const String _wakeUpMinuteKey = 'wake_up_minute';
  static const String _sleepHourKey = 'sleep_hour';
  static const String _sleepMinuteKey = 'sleep_minute';
  static const String _notificationIntervalKey = 'notification_interval_seconds';

  static const int defaultWakeUpHour = 7;
  static const int defaultWakeUpMinute = 0;
  static const int defaultSleepHour = 22;
  static const int defaultSleepMinute = 0;
  static const int defaultNotificationIntervalSeconds = 3600;

  Future<TimeOfDay> getWakeUpTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_wakeUpHourKey) ?? defaultWakeUpHour;
    final minute = prefs.getInt(_wakeUpMinuteKey) ?? defaultWakeUpMinute;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setWakeUpTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wakeUpHourKey, time.hour);
    await prefs.setInt(_wakeUpMinuteKey, time.minute);
  }

  Future<TimeOfDay> getSleepTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_sleepHourKey) ?? defaultSleepHour;
    final minute = prefs.getInt(_sleepMinuteKey) ?? defaultSleepMinute;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setSleepTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sleepHourKey, time.hour);
    await prefs.setInt(_sleepMinuteKey, time.minute);
  }

  Future<int> getNotificationInterval() async {
    return defaultNotificationIntervalSeconds; 
  }

  Future<void> setNotificationInterval(int intervalInSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notificationIntervalKey, intervalInSeconds);
  }
}