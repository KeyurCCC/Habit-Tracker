abstract class HabitEvent {}

class LoadHabitsEvent extends HabitEvent {
  final String userId;
  LoadHabitsEvent(this.userId);
}

class AddHabitEvent extends HabitEvent {
  final Map<String, dynamic> habitData;
  AddHabitEvent(this.habitData);
}

class DeleteHabitEvent extends HabitEvent {
  final String habitId;
  DeleteHabitEvent(this.habitId);
}
