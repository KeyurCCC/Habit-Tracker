abstract class GeminiChatEvent {}

/// When user sends a message to Gemini
class SendGeminiMessageEvent extends GeminiChatEvent {
  final String prompt;
  SendGeminiMessageEvent({required this.prompt});
}
