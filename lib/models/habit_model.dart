import 'package:cloud_firestore/cloud_firestore.dart';

class HabitModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String goalType;
  final int targetCount;
  final int completedCount;
  final int streak;
  final int longestStreak;
  final Timestamp lastCompletedAt;
  final Timestamp createdAt;

  HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.goalType,
    required this.targetCount,
    required this.completedCount,
    required this.streak,
    required this.longestStreak,
    required this.lastCompletedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'description': description,
    'goalType': goalType,
    'targetCount': targetCount,
    'completedCount': completedCount,
    'streak': streak,
    'longestStreak': longestStreak,
    'lastCompletedAt': lastCompletedAt,
    'createdAt': createdAt,
  };

  factory HabitModel.fromMap(Map<String, dynamic> map, String id) {
    return HabitModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      goalType: map['goalType'] ?? 'daily',
      targetCount: map['targetCount'] ?? 1,
      completedCount: map['completedCount'] ?? 0,
      streak: map['streak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastCompletedAt: map['lastCompletedAt'] ?? Timestamp.now(),
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}
