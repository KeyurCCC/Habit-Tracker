import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'habits/cubits/habit_cubit.dart';
import 'habits/cubits/habit_event.dart';
import 'habits/cubits/habit_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  static const String routeName = "/profile";

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    context.read<HabitCubit>().handleEvent(LoadHabitsEvent(userId));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: BlocBuilder<HabitCubit, HabitState>(
          builder: (context, state) {
            int totalHabits = 0;
            int totalStreak = 0;
            int completedToday = 0;

            if (state is HabitLoadedState) {
              totalHabits = state.habits.length;
              totalStreak = state.habits.fold(0, (sum, h) => sum + h.streak);
              final today = DateTime.now();
              completedToday = state.instances.where((i) {
                final d = i.date;
                return i.completed && d.year == today.year && d.month == today.month && d.day == today.day;
              }).length;
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Header with gradient
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profile',
                              style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_rounded, color: Colors.white),
                              onPressed: () => context.go('/settings'),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        // Profile Picture
                        Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: photoUrl != null
                                ? Image.network(photoUrl, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.white,
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 50.sp,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          displayName,
                          style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          email,
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),

                  // Stats Cards
                  Transform.translate(
                    offset: Offset(0, -30.h),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              context,
                              icon: Icons.list_alt_rounded,
                              value: totalHabits.toString(),
                              label: 'Habits',
                              color: const Color(0xFF667EEA),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _statCard(
                              context,
                              icon: Icons.local_fire_department_rounded,
                              value: totalStreak.toString(),
                              label: 'Streak',
                              color: const Color(0xFFFF6B6B),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _statCard(
                              context,
                              icon: Icons.check_circle_rounded,
                              value: completedToday.toString(),
                              label: 'Today',
                              color: const Color(0xFF51CF66),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // Menu Items
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        _menuItem(
                          context,
                          icon: Icons.insights_rounded,
                          title: 'Dashboard',
                          subtitle: 'View your progress',
                          onTap: () => context.go('/dashboardScreen'),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: 12.h),
                        _menuItem(
                          context,
                          icon: Icons.list_alt_rounded,
                          title: 'My Habits',
                          subtitle: 'Manage your habits',
                          onTap: () => context.go('/habitListScreen'),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        SizedBox(height: 12.h),
                        _menuItem(
                          context,
                          icon: Icons.chat_bubble_rounded,
                          title: 'AI Coach',
                          subtitle: 'Get personalized advice',
                          onTap: () => context.go('/geminiChatScreen'),
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        SizedBox(height: 12.h),
                        _menuItem(
                          context,
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          subtitle: 'App preferences',
                          onTap: () => context.go('/settings'),
                          color: Colors.orange,
                        ),
                        SizedBox(height: 24.h),
                        _menuItem(
                          context,
                          icon: Icons.logout_rounded,
                          title: 'Sign Out',
                          subtitle: 'Sign out of your account',
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        ),
      ),
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: color),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
