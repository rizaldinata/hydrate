import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hydrate/presentation/widgets/notificationWidgets/notificationMassage.dart';

class NotificationController {
  ///     INISIALISASI
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

  ///  Notifications events are only delivered after call this method
  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications()
        .setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  ///     NOTIFICATION EVENTS
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Handle action here
    print('Notification action received: ${receivedAction.actionType}');

    // You can add custom handling for different action types here
    if (receivedAction.actionType == ActionType.SilentAction) {
      print(
          'Silent action received with input: "${receivedAction.buttonKeyInput}"');
    }
  }

  ///     NOTIFICATION CREATION METHODS
  static Future<void> createNewNotification() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await requestNotificationPermission();
    }
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1, // -1 is replaced by a random number
            channelKey: 'alerts',
            title: 'Sudah waktunya minum air',
            body: HydrationMessages.getRandomMessage(),
            // bigPicture: 'https://storage.googleapis.com/cms-storage-bucket/d406c736e7c4c57f5f61.png',
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

// static Future<void> scheduleNotificationInSeconds(int seconds) async {
//   await AwesomeNotifications().createNotification(
//     schedule: NotificationInterval(
//       interval: Duration(seconds: seconds),
//       timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
//       repeats: false,
//       preciseAlarm: true, // untuk memastikan keakuratan waktu
//     ),
//     content: NotificationContent(
//       id: -1,
//       channelKey: 'alerts',
//       title: 'Waktunya Minum!',
//       body: 'Countdown selesai. Jangan lupa minum ya!',
//       notificationLayout: NotificationLayout.Default,
//     ),
//     actionButtons: [
//       NotificationActionButton(key: 'OPEN', label: 'Buka'),
//     ],
//   );
// }

  // static Future<void> scheduleNotification({
  //   required String title,
  //   required String body,
  //   required DateTime scheduleTime,
  //   String? imageUrl,
  //   Map<String, String>? payload,
  // }) async {
  //   bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  //   if (!isAllowed) {
  //     isAllowed = await requestNotificationPermission();
  //   }
  //   if (!isAllowed) return;

  //   await AwesomeNotifications().createNotification(
  //     schedule: NotificationCalendar.fromDate(date: scheduleTime),
  //     content: NotificationContent(
  //       id: -1,
  //       channelKey: 'alerts',
  //       title: title,
  //       body: body,
  //       bigPicture: imageUrl,
  //       notificationLayout: imageUrl != null ? NotificationLayout.BigPicture : NotificationLayout.Default,
  //       payload: payload,
  //     ),
  //     actionButtons: [
  //       NotificationActionButton(key: 'OPEN', label: 'Buka'),
  //       NotificationActionButton(
  //         key: 'DISMISS',
  //         label: 'Tutup',
  //         actionType: ActionType.DismissAction,
  //       ),
  //     ],
  //   );
  // }

  /// Request permission to send notifications
  static Future<bool> requestNotificationPermission() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  /// Reset notification badge counter
  static Future<void> resetBadgeCounter() async {
    await AwesomeNotifications().resetGlobalBadge();
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
