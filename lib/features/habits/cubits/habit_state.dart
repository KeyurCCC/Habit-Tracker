import '../../../models/habit_model.dart';
import '../../../models/habit_instance_model.dart';

abstract class HabitState {}

class HabitInitialState extends HabitState {}

class HabitLoadingState extends HabitState {}

class HabitLoadedState extends HabitState {
  final List<HabitModel> habits;
  final List<HabitInstanceModel> instances;

  HabitLoadedState(this.habits, this.instances);
}

class HabitSuccessState extends HabitState {}

class HabitErrorState extends HabitState {
  final String message;
  HabitErrorState(this.message);
}
