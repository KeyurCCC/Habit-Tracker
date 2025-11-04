import 'package:flutter/material.dart';
import 'package:flutter_pwa_demo/features/dashboard_screen.dart';
import 'package:flutter_pwa_demo/features/geminiChat/screens/gemini_chat_screen.dart';
import 'package:flutter_pwa_demo/features/habits/screens/habit_list_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const String routeName = "/homeScreen";

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now();
    final dateLabel = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0EA5E9)]),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back 👋', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14.sp)),
                        SizedBox(height: 6.h),
                        Text('Your Habits, Simplified', style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.w700)),
                        SizedBox(height: 8.h),
                        Text(dateLabel, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14.sp)),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: [
                      _homeActionCard(
                        context,
                        icon: Icons.add_task,
                        title: 'Add Habit',
                        subtitle: 'Create a new routine',
                        onTap: () => context.go(HabitListScreen.routeName),
                      ),
                      _homeActionCard(
                        context,
                        icon: Icons.insights,
                        title: 'Dashboard',
                        subtitle: 'Progress & streaks',
                        onTap: () => context.go(DashboardScreen.routeName),
                      ),
                      _homeActionCard(
                        context,
                        icon: Icons.chat_bubble_outline,
                        title: 'Gemini Chat',
                        subtitle: 'Ask your AI coach',
                        onTap: () => context.go(GeminiChatScreen.routeName),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _homeActionCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14.r),
    child: Container(
      width: 260.w,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12.r)),
            child: Icon(icon, color: const Color(0xFF0EA5E9), size: 22.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Text(subtitle, style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16.w, color: Colors.black45),
        ],
      ),
    ),
  );
}
