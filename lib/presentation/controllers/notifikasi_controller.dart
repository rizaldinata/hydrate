import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hydrate/presentation/widgets/notificationWidgets/notificationMassage.dart'; // Pastikan path ini benar
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController {
  /// Kunci SharedPreferences untuk status global notifikasi
  static const String _notificationsEnabledKey = 'notifications_enabled';

  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
        'resource://drawable/logo', // Pastikan 'logo' ada di folder drawable Anda
        [
          NotificationChannel(
              channelKey: 'alerts',
              channelName: 'Alerts',
              channelDescription: 'Notification tests as alerts',
              playSound: true,
              onlyAlertOnce: true, // Notifikasi dengan ID yang sama hanya berbunyi sekali
              groupAlertBehavior: GroupAlertBehavior.Children,
              importance: NotificationImportance.High,
              defaultPrivacy: NotificationPrivacy.Private,
              defaultColor: Colors.blue[100], // Warna aksen notifikasi
              ledColor: Colors.white // Warna LED notifikasi (jika didukung)
              )
        ],
        // Opsi untuk menampilkan log dari Awesome Notifications, berguna saat debugging
        debug: true);

    // Meminta izin notifikasi saat inisialisasi jika belum diberikan
    // Ini adalah praktik yang baik untuk memastikan izin diminta di awal.
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  /// Mendaftarkan semua listener yang diperlukan untuk event notifikasi.
  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod
      );
    print('[NotificationController] Notification listeners started.');
  }

  /// Dipanggil saat notifikasi BARU DIBUAT oleh sistem (baik terjadwal atau langsung).
  /// Ini adalah tempat yang tepat untuk menangani logika foreground.
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    print('[NotificationController] Notification CREATED. ID: ${receivedNotification.id}, Channel: ${receivedNotification.channelKey}, LifeCycle: ${receivedNotification.createdLifeCycle}');

    // Cek apakah aplikasi sedang di FOREGROUND saat notifikasi dibuat
    if (receivedNotification.createdLifeCycle == NotificationLifeCycle.Foreground) {
      print('[NotificationController] Notification created while app in FOREGROUND.');

      // Periksa preferensi global pengguna dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      bool areNotificationsGloballyEnabled = prefs.getBool(_notificationsEnabledKey) ?? false;

      if (!areNotificationsGloballyEnabled) {
        // Jika pengguna sudah menonaktifkan notifikasi dari ProfileScreen,
        // maka kita tidak ingin melakukan aksi foreground (misalnya, memainkan suara).
        // Kita juga akan mencoba membatalkan notifikasi ini agar tidak muncul di tray.
        print('[NotificationController] Notifications are globally DISABLED by user. Suppressing foreground notification action and attempting to cancel notification ID: ${receivedNotification.id}.');
        
        // Mencoba membatalkan notifikasi yang baru saja dibuat ini.
        // Ini mungkin tidak selalu berhasil menghentikan notifikasi sistem jika sudah "terlalu jauh" diproses,
        // tetapi ini adalah upaya terbaik untuk mencegahnya muncul di tray saat foreground dan dinonaktifkan.
        if (receivedNotification.id != null) {
            AwesomeNotifications().cancel(receivedNotification.id!);
        }
        return; // Keluar, jangan lakukan aksi foreground lainnya.
      }

      // Jika notifikasi global diaktifkan oleh pengguna,
      // Anda bisa menambahkan logika khusus di sini jika ingin ada perlakuan berbeda
      // untuk notifikasi yang datang saat aplikasi terbuka.
      // Misalnya, memainkan suara yang berbeda, atau menampilkan banner in-app.
      print('[NotificationController] Notifications are globally ENABLED. Processing foreground notification (if any custom action is defined).');
      // Contoh: Jika channelKey-nya 'alerts' dan Anda ingin memainkan suara khusus
      // if (receivedNotification.channelKey == 'alerts') {
      //   // Mainkan suara khusus untuk foreground
      // }
    }
  }

  /// Dipanggil saat notifikasi DITAMPILKAN ke pengguna.
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    print('[NotificationController] Notification DISPLAYED. ID: ${receivedNotification.id}, Channel: ${receivedNotification.channelKey}, LifeCycle: ${receivedNotification.displayedLifeCycle}');
    // Di sini Anda bisa melakukan logging, analitik, atau memperbarui UI jika perlu
    // (misalnya, jika notifikasi ditampilkan saat aplikasi di foreground).
  }

  /// Dipanggil saat pengguna MENUTUP (DISMISS) notifikasi.
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print('[NotificationController] Notification DISMISS action received. ID: ${receivedAction.id}');
    // Anda bisa menangani logika jika pengguna menutup notifikasi.
  }

  /// Dipanggil saat pengguna BERINTERAKSI dengan notifikasi (mengetuk notifikasi atau tombol aksi).
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print('[NotificationController] Notification ACTION received. ID: ${receivedAction.id}, ActionType: ${receivedAction.actionType}, ButtonKey: ${receivedAction.buttonKeyInput}');
    print('[NotificationController] Payload: ${receivedAction.payload}');

    // Contoh penanganan aksi:
    // Jika ada payload tertentu atau tombol tertentu ditekan, lakukan navigasi.
    // Pastikan Anda memiliki GlobalKey<NavigatorState> jika ingin navigasi dari luar widget tree.
    // Misalnya:
    // if (receivedAction.buttonKeyInput == 'REDIRECT' && receivedAction.payload != null) {
    //   // MyApp.navigatorKey.currentState?.pushNamed('/detail-page', arguments: receivedAction.payload);
    // }
  }

  /// Membuat notifikasi instan (bukan terjadwal).
  static Future<void> createNewNotification() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await requestNotificationPermission();
    }
    if (!isAllowed) {
      print("[NotificationController] Izin notifikasi ditolak, tidak dapat membuat notifikasi.");
      return;
    }

    // Periksa juga status global dari SharedPreferences sebelum membuat notifikasi instan
    final prefs = await SharedPreferences.getInstance();
    bool areNotificationsGloballyEnabled = prefs.getBool(_notificationsEnabledKey) ?? false;

    if (!areNotificationsGloballyEnabled) {
        print("[NotificationController] Notifikasi global dinonaktifkan oleh pengguna. Notifikasi instan tidak dibuat.");
        return;
    }

    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: -1, // ID -1 akan diganti dengan random oleh library
            channelKey: 'alerts', // Harus sama dengan channel yang diinisialisasi
            title: 'Sudah waktunya minum air',
            body: HydrationMessages.getRandomMessage(),
            largeIcon: 'asset://assets/images/logo.png', // Pastikan aset ini ada
            notificationLayout: NotificationLayout.BigText, // Tampilan notifikasi
            payload: {'notificationId': 'instant_reminder_123'},
            // WakeUpScreen: true, // Jika ingin membangunkan layar (gunakan dengan hati-hati)
            category: NotificationCategory.Reminder,
            ),
        actionButtons: [
          NotificationActionButton(key: 'REDIRECT', label: 'Buka Aplikasi'),
          NotificationActionButton(
              key: 'DISMISS',
              label: 'Tutup',
              actionType: ActionType.DismissAction,
              isDangerousOption: true, // Tandai jika aksi ini berpotensi menghapus sesuatu
              )
        ]);
    print("[NotificationController] Notifikasi instan berhasil dibuat.");
  }

  /// Menjadwalkan notifikasi hidrasi berulang.
  static Future<void> schedulePeriodicHydrationNotification({
    required int intervalInSeconds,
  }) async {
    // Izin sudah dicek di _onNotificationToggleChanged atau saat createNewNotification.
    // Namun, tidak ada salahnya mengecek lagi di sini untuk keamanan,
    // atau asumsikan sudah diizinkan jika fungsi ini dipanggil.
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      print("[NotificationController] Izin notifikasi ditolak, tidak dapat menjadwalkan.");
      // Anda mungkin ingin memberi tahu pengguna atau mengembalikan status gagal.
      return; 
    }
    
    // Pastikan interval minimal 60 detik jika berulang
    if (intervalInSeconds < 60) {
        print("[NotificationController] Interval penjadwalan ($intervalInSeconds detik) terlalu singkat. Minimal 60 detik untuk notifikasi berulang. Tidak menjadwalkan.");
        return; // Jangan jadwalkan jika interval tidak valid
    }

    String randomMessage = HydrationMessages.getRandomMessage();

    await AwesomeNotifications().createNotification(
        schedule: NotificationInterval(
          interval: Duration(seconds: intervalInSeconds), // Menggunakan interval dalam detik langsung
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
          repeats: true,
          preciseAlarm: true, // Untuk akurasi tinggi (memerlukan izin khusus di Android 12+)
          allowWhileIdle: true, // Izinkan berjalan saat mode Doze (gunakan dengan bijak)
        ),
        content: NotificationContent(
          id: 100, // ID statis untuk notifikasi periodik agar bisa dibatalkan/diperbarui
          channelKey: 'alerts',
          title: 'Waktunya Minum Air! 💧',
          body: randomMessage,
          notificationLayout: NotificationLayout.Default,
          payload: {'notificationId': 'hydration_reminder_periodic'},
          category: NotificationCategory.Reminder,
          // WakeUpScreen: true, // Jika ingin membangunkan layar
        ),
        actionButtons: [
          NotificationActionButton(key: 'REDIRECT', label: 'Buka Aplikasi'),
          NotificationActionButton(
              key: 'DISMISS',
              label: 'Tutup',
              actionType: ActionType.DismissAction,
              isDangerousOption: true)
        ]);
    print("[NotificationController] Notifikasi hidrasi dijadwalkan untuk berulang setiap $intervalInSeconds detik.");
  }

  /// Membatalkan SEMUA jadwal notifikasi.
  static Future<void> cancelScheduledNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
    // Untuk memastikan notifikasi yang mungkin sudah "aktif" (ID 100) juga dibatalkan
    await AwesomeNotifications().cancel(100); 
    print("[NotificationController] Semua jadwal notifikasi dan notifikasi aktif (ID 100) telah dibatalkan.");
  }

  /// Meminta izin kepada pengguna untuk mengirim notifikasi.
  static Future<bool> requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications(
        // Anda bisa menambahkan channelKey di sini jika ingin meminta izin untuk channel tertentu
        // channelKey: 'alerts', 
        permissions: [ // Jenis izin yang diminta
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          // NotificationPermission.Light, // Jika Anda menggunakan LED
          // NotificationPermission.CriticalAlert, // Untuk notifikasi sangat penting
        ]
      );
    }
    return isAllowed;
  }

  /// Mereset badge counter notifikasi (jika digunakan).
  static Future<void> resetBadgeCounter() async {
    await AwesomeNotifications().resetGlobalBadge();
    print("[NotificationController] Badge counter direset.");
  }

  /// Membatalkan semua notifikasi yang ditampilkan (bukan jadwal).
  static Future<void> cancelAllDisplayedNotifications() async {
    await AwesomeNotifications().cancelAll(); // Ini membatalkan notifikasi yang sedang tampil di tray
    print("[NotificationController] Semua notifikasi yang ditampilkan telah dibatalkan.");
  }
}
