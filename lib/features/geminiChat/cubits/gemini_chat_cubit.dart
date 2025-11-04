import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'gemini_chat_event.dart';
import 'gemini_chat_state.dart';

class GeminiChatCubit extends Cubit<GeminiChatState> {
  GeminiChatCubit() : super(GeminiChatInitialState());

  final List<GeminiMessage> _messages = [];

  Future<void> handleEvent(GeminiChatEvent event) async {
    if (event is SendGeminiMessageEvent) {
      await _sendMessage(event.prompt);
    }
  }

  Future<void> _sendMessage(String prompt) async {
    if (prompt.trim().isEmpty) return;

    _messages.add(GeminiMessage(role: "user", text: prompt));
    emit(GeminiChatLoadedState(messages: List.from(_messages)));

    emit(GeminiChatLoadingState(messages: List.from(_messages)));

    try {
      const model = "gemini-2.5-flash";
      const apiKey = "AIzaSyDHJlZDzyVHTRLMIpu5kfcwHsdFrimnhRQ"; // TODO: replace securely

      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "⚠️ No response from Gemini.";

        _messages.add(GeminiMessage(role: "gemini", text: reply));
        emit(GeminiChatLoadedState(messages: List.from(_messages)));
      } else {
        emit(
          GeminiChatErrorState(
            error: "Error ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown'}",
            messages: List.from(_messages),
          ),
        );
      }
    } catch (e) {
      emit(GeminiChatErrorState(error: e.toString(), messages: List.from(_messages)));
    }
  }
}
