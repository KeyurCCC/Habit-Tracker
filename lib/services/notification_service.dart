import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_web_stub.dart' if (dart.library.html) 'notification_web.dart' as web;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'habit_channel',
    'Habit Notifications',
    description: 'Notifications for habit actions',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (kIsWeb) return; // Local notifications not supported on web via this plugin

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_androidChannel);
  }

  static Future<void> sendNotification({required String userId, required String title, required String body}) async {
    // userId kept for signature compatibility; not used for local notifications
    if (kIsWeb) {
      await web.showWebNotification(title, body);
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'habit_channel',
      'Habit Notifications',
      channelDescription: 'Notifications for habit actions',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: false);
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(DateTime.now().millisecondsSinceEpoch % 100000, title, body, platformDetails);
  }
}
