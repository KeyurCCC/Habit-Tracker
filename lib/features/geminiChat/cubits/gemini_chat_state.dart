abstract class GeminiChatState {}

class GeminiChatInitialState extends GeminiChatState {}

class GeminiChatLoadingState extends GeminiChatState {
  final List<GeminiMessage> messages;
  GeminiChatLoadingState({required this.messages});
}

class GeminiChatLoadedState extends GeminiChatState {
  final List<GeminiMessage> messages;
  GeminiChatLoadedState({required this.messages});
}

class GeminiChatErrorState extends GeminiChatState {
  final String error;
  final List<GeminiMessage> messages;
  GeminiChatErrorState({required this.error, required this.messages});
}

/// Model class for messages
class GeminiMessage {
  final String role; // 'user' or 'gemini'
  final String text;

  GeminiMessage({required this.role, required this.text});
}
