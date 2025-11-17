import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/habit_model.dart';
import '../../../models/habit_instance_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/streak_calculator.dart';
import 'habit_event.dart';
import 'habit_state.dart';

class HabitCubit extends Cubit<HabitState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService firestoreService;
  StreamSubscription? _habitSubscription;

  HabitCubit({required this.firestoreService}) : super(HabitInitialState());

  void handleEvent(HabitEvent event) {
    if (event is LoadHabitsEvent) {
      _loadHabits(event.userId);
    } else if (event is AddHabitEvent) {
      _addHabit(event.habitData);
    } else if (event is DeleteHabitEvent) {
      _deleteHabit(event.habitId);
    }
  }

  void _loadHabits(String userId) {
    emit(HabitLoadingState());
    _habitSubscription?.cancel();

    _habitSubscription = _firestore.collection('habits').where('userId', isEqualTo: userId).snapshots().listen((
      snapshot,
    ) async {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        // Fetch habit documents
        final habits = snapshot.docs.map((d) => HabitModel.fromMap(d.data(), d.id)).toList();
        // Fetch all habit instances
        final instances = await firestoreService.getHabitInstances(userId!);

        // Calculate streak for each habit
        final updatedHabits = habits.map((habit) {
          final habitInstances = instances.where((i) => i.habitId == habit.id && i.completed).toList();

          final streak = calculateStreak(habitInstances);
          return HabitModel(
            id: habit.id,
            userId: habit.userId,
            title: habit.title,
            description: habit.description,
            goalType: habit.goalType,
            targetCount: habit.targetCount,
            completedCount: habit.completedCount,
            streak: streak, // updated
            lastCompletedAt: habit.lastCompletedAt,
            createdAt: habit.createdAt,
          );
        }).toList();

        emit(HabitLoadedState(updatedHabits, instances));
      } catch (e) {
        emit(HabitErrorState(e.toString()));
      }
    });
  }

  Future<void> loadDashboardData(String userId) async {
    try {
      emit(HabitLoadingState());

      // ✅ Fetch all user habits and instances
      final habits = await firestoreService.getHabits(userId);
      final instances = await firestoreService.getHabitInstances(userId);

      // ✅ Calculate streaks for each habit
      final updatedHabits = habits.map((habit) {
        final habitInstances = instances.where((i) => i.habitId == habit.id && i.completed).toList();

        final streak = calculateStreak(habitInstances);

        return HabitModel(
          id: habit.id,
          userId: habit.userId,
          title: habit.title,
          description: habit.description,
          goalType: habit.goalType,
          targetCount: habit.targetCount,
          completedCount: habit.completedCount,
          streak: streak,
          lastCompletedAt: habit.lastCompletedAt,
          createdAt: habit.createdAt,
        );
      }).toList();

      emit(HabitLoadedState(updatedHabits, instances));
    } catch (e) {
      emit(HabitErrorState(e.toString()));
    }
  }

  Future<void> _addHabit(Map<String, dynamic> habitData) async {
    try {
      await _firestore.collection('habits').doc(habitData['id']).set(habitData);
      // ✅ Send FCM notification
      await NotificationService.sendNotification(
        userId: habitData['userId'],
        title: "New Habit Added 🎯",
        body: "You added \"${habitData['title']}\" to your habit list!",
      );
      emit(HabitSuccessState());
    } catch (e) {
      emit(HabitErrorState(e.toString()));
    }
  }

  Future<void> _deleteHabit(String habitId) async {
    try {
      await _firestore.collection('habits').doc(habitId).delete();
      emit(HabitSuccessState());
    } catch (e) {
      emit(HabitErrorState(e.toString()));
    }
  }

  // 🔹 ADD THIS — Mark habit as completed for today
  Future<void> addHabitInstance(String habitId, String userId) async {
    try {
      final today = DateTime.now();
      final docId = "${today.year}-${today.month}-${today.day}";

      await _firestore.collection('habits').doc(habitId).collection('instances').doc(docId).set({
        'date': today,
        'completed': true,
      }, SetOptions(merge: true));

      // Update streak after adding instance
      await _updateStreak(habitId);

      // ✅ Fetch habit title for notification
      final habitDoc = await _firestore.collection('habits').doc(habitId).get();
      final habitTitle = habitDoc.data()?['title'] ?? 'a habit';

      // ✅ Send FCM notification
      await NotificationService.sendNotification(
        userId: userId,
        title: "Habit Completed ✅",
        body: "You completed \"$habitTitle\" today! Keep it up 🔥",
      );
    } catch (e) {
      emit(HabitErrorState(e.toString()));
    }
  }

  // 🔹 ADD THIS — Auto calculate streak based on consecutive completed days
  Future<void> _updateStreak(String habitId) async {
    final snapshot = await _firestore
        .collection('habits')
        .doc(habitId)
        .collection('instances')
        .orderBy('date', descending: true)
        .get();

    int streak = 0;
    DateTime? prevDate;

    for (var doc in snapshot.docs) {
      final dateValue = doc['date'];
      late DateTime date;
      
      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        continue;
      }

      // Normalize to midnight for proper day comparison
      date = DateTime(date.year, date.month, date.day);
      
      final completed = doc['completed'] ?? false;

      if (!completed) continue;

      if (prevDate == null) {
        streak = 1;
        prevDate = date;
      } else {
        final diff = prevDate.difference(date).inDays;
        if (diff == 1) {
          // Consecutive day
          streak++;
          prevDate = date;
        } else if (diff > 1) {
          // Gap found - streak broken
          break;
        }
        // if diff == 0, skip duplicate date entry
      }
    }

    await _firestore.collection('habits').doc(habitId).update({'streak': streak});
  }

  @override
  Future<void> close() {
    _habitSubscription?.cancel();
    return super.close();
  }
}
