import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_model.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';

class DailySuggestionService {
  /// Generate and send daily habit suggestions via notification
  static Future<void> generateAndNotifyDailySuggestions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user's habits
      final habitsSnapshot = await FirebaseFirestore.instance
          .collection('habits')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (habitsSnapshot.docs.isEmpty) return;

      final habits = habitsSnapshot.docs
          .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
          .toList();

      // Generate suggestion using Gemini
      final suggestion = await GeminiService.generateDailySuggestions(
        userId: user.uid,
        habits: habits,
      );

      // Send notification with suggestion
      await NotificationService.sendNotification(
        userId: user.uid,
        title: '💡 Daily Habit Reminder',
        body: suggestion,
      );
    } catch (e) {
      print('Error generating daily suggestion: $e');
      // Fail silently - don't interrupt user experience
    }
  }

  /// Check if suggestion was already sent today
  static Future<bool> hasSuggestionBeenSentToday(String userId) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('daily_suggestions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Mark suggestion as sent for today
  static Future<void> markSuggestionSent(String userId, String suggestion) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('daily_suggestions')
          .add({
        'suggestion': suggestion,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking suggestion sent: $e');
    }
  }

  /// Generate and send suggestion (with duplicate check)
  static Future<void> generateAndNotifyWithCheck() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if already sent today
      final alreadySent = await hasSuggestionBeenSentToday(user.uid);
      if (alreadySent) {
        print('Suggestion already sent today');
        return;
      }

      // Generate and send
      await generateAndNotifyDailySuggestions();

      // Mark as sent
      final habitsSnapshot = await FirebaseFirestore.instance
          .collection('habits')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (habitsSnapshot.docs.isNotEmpty) {
        final habits = habitsSnapshot.docs
            .map((doc) => HabitModel.fromMap(doc.data(), doc.id))
            .toList();

        final suggestion = await GeminiService.generateDailySuggestions(
          userId: user.uid,
          habits: habits,
        );

        await markSuggestionSent(user.uid, suggestion);
      }
    } catch (e) {
      print('Error in generateAndNotifyWithCheck: $e');
    }
  }
}

