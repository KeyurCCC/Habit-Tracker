import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../habits/cubits/habit_cubit.dart';
import '../habits/cubits/habit_event.dart';
import '../habits/cubits/habit_state.dart';
import '../../services/notification_service.dart';

class ScheduledNotificationsScreen extends StatefulWidget {
  static const String routeName = "/scheduledNotifications";
  const ScheduledNotificationsScreen({super.key});

  @override
  State<ScheduledNotificationsScreen> createState() => _ScheduledNotificationsScreenState();
}

class _ScheduledNotificationsScreenState extends State<ScheduledNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      context.read<HabitCubit>().handleEvent(LoadHabitsEvent(userId));
    }
  }

  Future<void> _cancelReminder(String habitId, int hour) async {
    try {
      final id = habitId.hashCode ^ (hour << 8) ^ 0;
      await NotificationService.cancelNotification(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Reminder cancelled')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Scheduled Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: BlocBuilder<HabitCubit, HabitState>(
        builder: (context, state) {
          if (state is HabitLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HabitLoadedState) {
            final now = DateTime.now();
            final habitsWithStreaks = state.habits
                .where((h) => h.streak > 0)
                .toList();

            final habitsNotCompletedToday = habitsWithStreaks.where((h) {
              final completed = state.instances.any((i) {
                final d = i.date;
                return i.habitId == h.id && i.completed && d.year == now.year && d.month == now.month && d.day == now.day;
              });
              return !completed;
            }).toList();

            if (habitsNotCompletedToday.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.done_all, size: 64.sp, color: Colors.grey.shade300),
                    SizedBox(height: 16.h),
                    Text(
                      'No scheduled reminders',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'All habits completed today or no active streaks',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: habitsNotCompletedToday.length,
              itemBuilder: (context, index) {
                final habit = habitsNotCompletedToday[index];
                return _buildReminderCard(context, habit);
              },
            );
          }

          return const Center(child: Text('Error loading habits'));
        },
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, dynamic habit) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_fire_department, color: Colors.orange, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${habit.streak}-day streak',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReminderTime('🌙 Evening Reminder', '21:00'),
                  SizedBox(height: 8.h),
                  _buildReminderTime('⏰ Final Reminder', '23:55'),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _cancelReminder(habit.id, 21),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancel All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTime(String label, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500)),
        Text(time, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
      ],
    );
  }
}
