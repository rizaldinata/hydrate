import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hydrate/presentation/widgets/notificationWidgets/notificationMassage.dart';
import 'package:hydrate/services/notification_settings_service.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const int kScheduledHydrationNotificationId = 10;

  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
        'resource://drawable/logo', 
        [
          NotificationChannel(
              channelKey: 'alerts',
              channelName: 'Alerts',
              channelDescription: 'Notification tests as alerts',
              playSound: true,
              onlyAlertOnce: true, 
              groupAlertBehavior: GroupAlertBehavior.Children,
              importance: NotificationImportance.High,
              defaultPrivacy: NotificationPrivacy.Private,
              defaultColor: Colors.blue[100], 
              ledColor: Colors.white 
              )
        ],
        debug: true);

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod
      );
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    if (receivedNotification.createdLifeCycle == NotificationLifeCycle.Foreground) {
      final prefs = await SharedPreferences.getInstance();
      bool areNotificationsGloballyEnabled = prefs.getBool(_notificationsEnabledKey) ?? false;

      if (!areNotificationsGloballyEnabled) {
        
        if (receivedNotification.id != null) {
            AwesomeNotifications().cancel(receivedNotification.id!);
        }
        return; 
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {    
  }

  static Future<void> createNewNotification() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await requestNotificationPermission();
    }
    if (!isAllowed) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    bool areNotificationsGloballyEnabled = prefs.getBool(_notificationsEnabledKey) ?? false;

    if (!areNotificationsGloballyEnabled) {
        return;
    }

    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1, 
            channelKey: 'alerts', 
            title: 'Sudah waktunya minum air',
            body: HydrationMessages.getRandomMessage(),
            largeIcon: 'asset://assets/images/logo.png',
            notificationLayout: NotificationLayout.BigText,
            payload: {'notificationId': 'instant_reminder_123'},
            category: NotificationCategory.Reminder,
            ),
        actionButtons: [
          NotificationActionButton(key: 'REDIRECT', label: 'Buka Aplikasi'),
          NotificationActionButton(
              key: 'DISMISS',
              label: 'Tutup',
              actionType: ActionType.DismissAction,
              isDangerousOption: true,
              )
        ]);
  }

  static Future<void> cancelScheduledNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
    await AwesomeNotifications().cancel(100); 
  }

  static Future<bool> requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
        ]
      );
    }
    return isAllowed;
  }

  static Future<void> resetBadgeCounter() async {
    await AwesomeNotifications().resetGlobalBadge();
  }

  static Future<void> cancelAllDisplayedNotifications() async {
    await AwesomeNotifications().cancelAll(); 
  }

  static Future<void> scheduleNextHydrationNotification({
    required DateTime exactNotificationTime,
    String title = 'Saatnya Minum! 💧',
    String body = 'Jangan lupa jaga hidrasi Anda hari ini.', 
    int notificationId = NotificationController.kScheduledHydrationNotificationId,
    Map<String, String?>? payload, 
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'alerts',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar.fromDate(
        date: exactNotificationTime,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> scheduleNextWakeUpNotification() async {
    final TimeOfDay wakeUp = await NotificationSettingsService().getWakeUpTime();
    DateTime now = DateTime.now();
    DateTime todayWakeUp = DateTime(now.year, now.month, now.day, wakeUp.hour, wakeUp.minute);
    DateTime nextWakeUpNotificationTime;

    if (now.isBefore(todayWakeUp)) {
      nextWakeUpNotificationTime = todayWakeUp;
    } else {
      nextWakeUpNotificationTime = todayWakeUp.add(const Duration(days: 1));
    }
    
    nextWakeUpNotificationTime = nextWakeUpNotificationTime.add(const Duration(seconds: 10));

    await AwesomeNotifications().cancel(200);

    await NotificationController.scheduleNextHydrationNotification(
        exactNotificationTime: nextWakeUpNotificationTime,
        title: 'Selamat Pagi! Waktunya Minum Air 💧',
        body: 'Mulailah harimu dengan segelas air untuk menjaga hidrasi.',
        notificationId: 200,
    );
  }
}
