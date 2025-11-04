import '../models/habit_instance_model.dart';

int calculateStreak(List<HabitInstanceModel> instances) {
  if (instances.isEmpty) return 0;
  instances.sort((a, b) => b.date.compareTo(a.date));

  int streak = 0;
  DateTime today = DateTime.now();

  for (var i = 0; i < instances.length; i++) {
    final diff = today.difference(instances[i].date).inDays;
    if (diff == streak && instances[i].completed) {
      streak++;
    } else if (diff > streak) {
      break;
    }
  }
  return streak;
}
