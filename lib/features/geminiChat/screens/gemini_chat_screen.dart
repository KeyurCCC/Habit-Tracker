import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../cubits/gemini_chat_cubit.dart';
import '../cubits/gemini_chat_event.dart';
import '../cubits/gemini_chat_state.dart';

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});
  static const String routeName = "/geminiChatScreen";

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<GeminiChatCubit>().handleEvent(SendGeminiMessageEvent(prompt: text));
    _controller.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("💬 Gemini Chat"), backgroundColor: Colors.grey[500], centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<GeminiChatCubit, GeminiChatState>(
                listener: (context, state) => _scrollToBottom(),
                builder: (context, state) {
                  List<GeminiMessage> messages = [];
                  bool isThinking = false;

                  if (state is GeminiChatLoadedState) {
                    messages = state.messages;
                  } else if (state is GeminiChatLoadingState) {
                    messages = state.messages;
                    isThinking = true;
                  } else if (state is GeminiChatErrorState) {
                    messages = state.messages;
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    itemCount: isThinking ? messages.length + 1 : messages.length,
                    itemBuilder: (context, index) {
                      if (index < messages.length) {
                        final msg = messages[index];
                        final isUser = msg.role == "user";

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: 0.75.sw, // bubble width responsive
                            ),
                            margin: EdgeInsets.symmetric(vertical: 6.h),
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.grey[500] : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16.r),
                                topRight: Radius.circular(16.r),
                                bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
                                bottomRight: Radius.circular(isUser ? 4.r : 16.r),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 15.sp,
                                height: 1.4,
                              ),
                            ),
                          ),
                        );
                      }
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 0.75.sw),
                          margin: EdgeInsets.symmetric(vertical: 6.h),
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16.r)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                "Gemini is thinking...",
                                style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Input area
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(fontSize: 16.sp),
                      decoration: InputDecoration(
                        hintText: "Ask anything",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(context),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  InkWell(
                    onTap: () => _sendMessage(context),
                    borderRadius: BorderRadius.circular(50.r),
                    child: CircleAvatar(
                      radius: 25.r,
                      backgroundColor: Colors.grey[500],
                      child: Icon(Icons.send, color: Colors.white, size: 22.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
