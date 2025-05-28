import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hydrate/presentation/widgets/notificationWidgets/notificationMassage.dart';

class NotificationController {
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
              ledColor: Colors.white)
        ],
        debug: true);
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications()
        .setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print('Notification action received: ${receivedAction.actionType}');

    if (receivedAction.actionType == ActionType.SilentAction) {
      print(
          'Silent action received with input: "${receivedAction.buttonKeyInput}"');
    }
  }

  static Future<void> createNewNotification() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await requestNotificationPermission();
    }
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1,
            channelKey: 'alerts',
            title: 'Sudah waktunya minum air',
            body: HydrationMessages.getRandomMessage(),
            largeIcon: 'asset://assets/images/logo.png',
            notificationLayout: NotificationLayout.BigText,
            payload: {'notificationId': '1234567890'},
            
        ),
        actionButtons: [
          NotificationActionButton(key: 'REDIRECT', label: 'Buka'),
          NotificationActionButton(
              key: 'DISMISS',
              label: 'Tutup',
              actionType: ActionType.DismissAction)
        ]);
  }

  static Future<void> schedulePeriodicHydrationNotification({
    required int intervalInSeconds,
  }) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await requestNotificationPermission();
    }
    if (!isAllowed) return;

    String randomMessage = HydrationMessages.getRandomMessage(); 

    await AwesomeNotifications().createNotification(
      schedule: NotificationInterval(
        interval: Duration(seconds: intervalInSeconds),
        timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        repeats: true, 
        preciseAlarm: true,
      ),
      content: NotificationContent(
        id: 100, 
        channelKey: 'alerts',
        title: 'Waktunya Minum Air! 💧',
        body: randomMessage,
        notificationLayout: NotificationLayout.Default,
        payload: {'notificationId': 'hydration_reminder'},
      ),
      actionButtons: [
        NotificationActionButton(key: 'REDIRECT', label: 'Buka Aplikasi'),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Tutup',
          actionType: ActionType.DismissAction,
        )
      ],
    );
    print("Notifikasi hidrasi dijadwalkan untuk berulang setiap $intervalInSeconds detik.");
  }

  static Future<void> cancelScheduledNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
    print("Semua notifikasi terjadwal telah dibatalkan.");
  }
  static Future<bool> requestNotificationPermission() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  static Future<void> resetBadgeCounter() async {
    await AwesomeNotifications().resetGlobalBadge();
  }
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
