import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_web_stub.dart' if (dart.library.html) 'notification_web.dart' as web;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

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

    await _configureLocalTimeZone();

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _configureLocalTimeZone() async {
    try {
      tzdata.initializeTimeZones();
      final String localTimeZone = await FlutterNativeTimezone.getLocalTimezone();
      final location = tz.getLocation(localTimeZone);
      tz.setLocalLocation(location);
    } catch (e) {
      // If timezone initialization fails, default to UTC
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
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

  static NotificationDetails get _platformDetails {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'habit_channel',
      'Habit Notifications',
      channelDescription: 'Notifications for habit actions',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: false);
    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  static Future<void> scheduleDailyReminder({required int id, required String title, required String body, required int hour, required int minute}) async {
    if (kIsWeb) {
      // Web doesn't support scheduled local notifications in this setup — show immediate web notification as fallback
      await web.showWebNotification(title, body);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  static Future<void> cancelAllScheduled() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}
