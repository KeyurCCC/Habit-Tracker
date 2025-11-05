import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../cubits/habit_cubit.dart';
import '../cubits/habit_event.dart';
import '../cubits/habit_state.dart';
import 'add_habit_screen.dart';

class HabitListScreen extends StatelessWidget {
  const HabitListScreen({super.key});

  static const String routeName = "/habitListScreen";

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    context.read<HabitCubit>().handleEvent(LoadHabitsEvent(userId));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('My Habits')),
      body: BlocBuilder<HabitCubit, HabitState>(
        builder: (context, state) {
          if (state is HabitLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HabitLoadedState) {
            if (state.habits.isEmpty) {
              return const Center(child: Text('No habits yet.'));
            }
            final instances = state.instances;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.habits.length,
              itemBuilder: (context, index) {
                final habit = state.habits[index];
                final habitInstances = instances.where((i) => i.habitId == habit.id).toList();
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: IconButton(
                      icon: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.secondary),
                      onPressed: () {
                        context.read<HabitCubit>().addHabitInstance(habit.id, habit.userId);
                      },
                    ),
                    title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text('Streak: ${habit.streak} • Target: ${habit.targetCount}', style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                        _sevenDayStrip(habitInstances),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          context.read<HabitCubit>().handleEvent(DeleteHabitEvent(habit.id));
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (state is HabitErrorState) {
            return Center(child: Text('Error: ${state.message}'));
          } else {
            return const Center(child: Text('Something went wrong.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AddHabitScreen.routeName);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

Widget _sevenDayStrip(List habitInstances) {
  final now = DateTime.now();
  final days = List.generate(7, (idx) {
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - idx));
    final done = habitInstances.any((i) {
      final d = i.date;
      return i.completed && d.year == day.year && d.month == day.month && d.day == day.day;
    });
    return done;
  });

  return Row(
    children: [
      for (final done in days) ...[
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: done ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
        ),
      ]
    ],
  );
}
