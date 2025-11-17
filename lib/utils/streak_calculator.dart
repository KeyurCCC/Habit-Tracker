import '../models/habit_instance_model.dart';

int calculateStreak(List<HabitInstanceModel> instances) {
  if (instances.isEmpty) return 0;

  // Filter only completed instances
  final completed = instances.where((i) => i.completed).toList();
  if (completed.isEmpty) return 0;

  // Sort by date in descending order (most recent first)
  completed.sort((a, b) => b.date.compareTo(a.date));

  // Normalize today to midnight for proper comparison
  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);

  int streak = 0;
  DateTime? lastDate;

  for (var instance in completed) {
    // Normalize instance date to midnight
    final instanceDate = DateTime(instance.date.year, instance.date.month, instance.date.day);

    if (lastDate == null) {
      // First iteration - check if it's today or yesterday
      final diff = todayMidnight.difference(instanceDate).inDays;
      if (diff == 0 || diff == 1) {
        streak = 1;
        lastDate = instanceDate;
      } else {
        // Streak broken - first completion is not recent
        break;
      }
    } else {
      // Check for consecutive day
      final diff = lastDate.difference(instanceDate).inDays;
      if (diff == 1) {
        // Consecutive day found
        streak++;
        lastDate = instanceDate;
      } else if (diff > 1) {
        // Gap found - streak broken
        break;
      }
      // if diff == 0, skip duplicate
    }
  }

  return streak;
}
