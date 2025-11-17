import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_pwa_demo/features/dashboard_screen.dart';
import 'package:flutter_pwa_demo/features/geminiChat/screens/gemini_chat_screen.dart';
import 'package:flutter_pwa_demo/features/habits/screens/habit_list_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'habits/screens/add_habit_screen.dart';
import 'habits/cubits/habit_cubit.dart';
import 'habits/cubits/habit_event.dart';
import 'habits/cubits/habit_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const String routeName = "/homeScreen";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load habits data only once when screen is initialized
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      context.read<HabitCubit>().handleEvent(LoadHabitsEvent(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now();
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1];
    final month = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][date.month - 1];
    final dateLabel = "$weekday, ${date.day} $month";

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Theme.of(context).colorScheme.primary.withOpacity(0.08), Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: BlocBuilder<HabitCubit, HabitState>(
              builder: (context, state) {
                // Calculate stats from habit data
                int totalHabits = 0;
                int completedToday = 0;
                int totalStreak = 0;
                double progressPercent = 0.0;

                if (state is HabitLoadedState) {
                  final habits = state.habits;
                  final instances = state.instances;
                  final today = DateTime.now();

                  totalHabits = habits.length;
                  totalStreak = habits.fold(0, (sum, h) => sum + h.streak);

                  completedToday = instances.where((i) {
                    final d = i.date;
                    return i.completed && d.year == today.year && d.month == today.month && d.day == today.day;
                  }).length;

                  if (totalHabits > 0) {
                    progressPercent = (completedToday / totalHabits) * 100;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Welcome Card
                    _buildWelcomeCard(context, dateLabel),
                    SizedBox(height: 16.h),

                    // Quick Stats Section with real data
                    _buildQuickStats(context, totalStreak, completedToday, progressPercent),
                    SizedBox(height: 16.h),

                    // Action Cards Grid
                    Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                    ),
                    SizedBox(height: 10.h),
                    _buildActionCardsGrid(context),
                    SizedBox(height: 14.h),

                    // Motivational Quote Card
                    _buildMotivationalCard(context),
                    SizedBox(height: 10.h),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String dateLabel) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.celebration, color: Colors.white, size: 18.sp),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  dateLabel,
                  style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Welcome back! 👋',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4.h),
          Text(
            'Ready to build amazing habits today?',
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, int totalStreak, int completedToday, double progressPercent) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            icon: Icons.local_fire_department,
            value: totalStreak.toString(),
            label: 'Day Streak',
            color: const Color(0xFFFF6B6B),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.check_circle,
            value: completedToday.toString(),
            label: 'Completed',
            color: const Color(0xFF51CF66),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.trending_up,
            value: '${progressPercent.toStringAsFixed(0)}%',
            label: 'Progress',
            color: const Color(0xFF4DABF7),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCardsGrid(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 900;

      final cards = [
        _homeActionCard(
          context,
          icon: Icons.add_task_rounded,
          title: 'Add Habit',
          subtitle: 'Create new',
          gradient: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
          onTap: () => context.push(AddHabitScreen.routeName),
        ),
        _homeActionCard(
          context,
          icon: Icons.insights_rounded,
          title: 'Dashboard',
          subtitle: 'Track',
          gradient: [const Color(0xFFF093FB), const Color(0xFFF5576C)],
          onTap: () => context.go(DashboardScreen.routeName),
        ),
        _homeActionCard(
          context,
          icon: Icons.chat_bubble_rounded,
          title: 'AI Coach',
          subtitle: 'Get help',
          gradient: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
          onTap: () => context.go(GeminiChatScreen.routeName),
        ),
        _homeActionCard(
          context,
          icon: Icons.list_alt_rounded,
          title: 'My Habits',
          subtitle: 'View all',
          gradient: [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
          onTap: () => context.go(HabitListScreen.routeName),
        ),
      ];

      if (isWide) {
        // Single row with equal-width cards on wide screens
        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(
                child: SizedBox(
                  height: 140.h,
                  child: cards[i],
                ),
              ),
              if (i != cards.length - 1) SizedBox(width: 12.w),
            ]
          ],
        );
      }

      // Fallback: two-column grid for smaller screens
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.0,
        children: cards,
      );
    });
  }

  Widget _homeActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: Colors.white, size: 20.sp),
              ),
              SizedBox(height: 10.h),
              Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationalCard(BuildContext context) {
    final quotes = [
      "Small steps every day lead to big changes! 🌟",
      "You're one habit away from a better life! 💪",
      "Consistency beats perfection every time! ✨",
      "Your future self will thank you! 🎯",
    ];
    final quote = quotes[DateTime.now().day % quotes.length];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Theme.of(context).colorScheme.tertiary.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Motivation',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                SizedBox(height: 2.h),
                Text(
                  quote,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
