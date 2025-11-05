// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> showWebNotification(String title, String body) async {
  try {
    if (html.Notification.supported) {
      final permission = await html.Notification.requestPermission();
      if (permission == 'granted') {
        html.Notification(title, body: body, icon: '/icons/Icon-192.png');
      }
    }
  } catch (_) {}
}


