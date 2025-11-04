import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static const String _serverKey =
      'BMqR_hlD_J87qOeSXLBP_fZleNy_-BaqKOXUJVcL9is1nUJSwZz6FOJ8kUsP01XtcH4tdVR3yqumUJMgilwm4jQ'; // Replace this

  static Future<void> sendNotification({required String userId, required String title, required String body}) async {
    try {
      // Get user’s FCM token
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final token = userDoc.data()?['fcmToken'];

      if (token == null) {
        print('❌ No FCM token for user $userId');
        return;
      }

      // Build notification payload
      final payload = {
        'to': token,
        'notification': {'title': title, 'body': body, 'sound': 'default'},
        'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
      };

      // Send notification using FCM HTTP API
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'key=$_serverKey'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Notification sent to $userId');
      } else {
        print('⚠️ Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }
}
