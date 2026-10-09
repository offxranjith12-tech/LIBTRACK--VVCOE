import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps Firebase Cloud Messaging + flutter_local_notifications.
///
/// Firebase is intentionally NOT auto-initialized here because it requires
/// `google-services.json` / `GoogleService-Info.plist` for this specific
/// Firebase project. Steps:
///   1. Run `flutterfire configure` (or add the config files manually).
///   2. Call `Firebase.initializeApp()` in `main()` before `runApp`.
///   3. Call `PushNotificationService.instance.init()` after that.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(initSettings);

    _initialized = true;

    // Uncomment once Firebase.initializeApp() has run in main():
    //
    // FirebaseMessaging.onMessage.listen((message) {
    //   showLocalNotification(
    //     title: message.notification?.title ?? 'LibTrack',
    //     body: message.notification?.body ?? '',
    //   );
    // });
    // await FirebaseMessaging.instance.requestPermission();
  }

  Future<void> showLocalNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'libtrack_channel',
      'LibTrack Notifications',
      channelDescription: 'Due reminders, new arrivals, and library announcements',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
