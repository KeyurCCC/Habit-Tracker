import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_model.dart';

class GeminiService {
  // For production, use flutter_dotenv or secure storage
  static const String _apiKey = 'AIzaSyDHJlZDzyVHTRLMIpu5kfcwHsdFrimnhRQ';
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Generate daily habit summary using Gemini AI
  static Future<String> generateDailySummary({required String userId, required List<HabitModel> habits}) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Please set your Gemini API key in lib/services/gemini_service.dart');
    }

    if (habits.isEmpty) {
      throw Exception('No habits found for user');
    }

    // Build prompt
    final prompt =
        '''User ID: $userId
Today's habit progress:
${habits.map((h) => '- ${h.title}: streak ${h.streak}, completed ${h.completedCount}/${h.targetCount}').join('\n')}

Generate a motivational daily summary and advice in a friendly tone.''';

    // Call Gemini API
    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = response.body;
      throw Exception('Gemini API error: ${response.statusCode} - $errorBody');
    }

    final data = jsonDecode(response.body);
    final summary = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'No summary generated.';

    return summary;
  }

  /// Generate daily activity suggestions using Gemini AI
  /// Returns actionable steps/suggestions for completing habits
  static Future<String> generateDailySuggestions({
    required String userId,
    required List<HabitModel> habits,
  }) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Please set your Gemini API key in lib/services/gemini_service.dart');
    }

    if (habits.isEmpty) {
      throw Exception('No habits found for user');
    }

    // Find incomplete habits for today
    final today = DateTime.now();
    final incompleteHabits = habits.where((h) {
      // You can add logic here to check if habit is incomplete today
      return true; // For now, suggest for all habits
    }).toList();

    // Build prompt for actionable suggestions
    final prompt = '''User ID: $userId
Current habits:
${habits.map((h) => '- ${h.title}: streak ${h.streak} days, target: ${h.targetCount} per ${h.goalType}').join('\n')}

Generate a short, actionable daily suggestion (max 100 characters) with specific steps to help the user complete their habits today. 
Format: "💡 [Actionable step/reminder]"
Example: "💡 Start with 5 minutes of meditation to keep your streak going!"
Keep it motivational and specific.''';

    // Call Gemini API
    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = response.body;
      throw Exception('Gemini API error: ${response.statusCode} - $errorBody');
    }

    final data = jsonDecode(response.body);
    final suggestion = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Keep working on your habits today!';

    return suggestion.trim();
  }

  /// Generate and save daily summary to Firestore
  static Future<void> generateAndSaveSummary({required String userId, required List<HabitModel> habits}) async {
    try {
      // Generate summary
      final summary = await generateDailySummary(userId: userId, habits: habits);

      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('daily_summaries').add({
        'summary': summary,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
