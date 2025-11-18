// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class HabitInstanceModel {
//   final String id;
//   final String habitId;
//   final String userId;
//   final Timestamp date;
//   final bool completed;
//
//   HabitInstanceModel({
//     required this.id,
//     required this.habitId,
//     required this.userId,
//     required this.date,
//     required this.completed,
//   });
//
//   Map<String, dynamic> toMap() => {
//     'id': id,
//     'habitId': habitId,
//     'userId': userId,
//     'date': date,
//     'completed': completed,
//   };
//
//   factory HabitInstanceModel.fromMap(Map<String, dynamic> map, String id) {
//     return HabitInstanceModel(
//       id: id,
//       habitId: map['habitId'] ?? '',
//       userId: map['userId'] ?? '',
//       date: map['date'] ?? Timestamp.now(),
//       completed: map['completed'] ?? false,
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';

class HabitInstanceModel {
  final String id;
  final String habitId;
  final String userId;
  final DateTime date;
  final bool completed;

  HabitInstanceModel({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    required this.completed,
  });

  factory HabitInstanceModel.fromMap(Map<String, dynamic> data, String id) {
    final timestamp = data['date'];
    DateTime dateTime;

    // Convert Timestamp or String to DateTime
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      dateTime = DateTime.parse(timestamp);
    } else {
      dateTime = DateTime.now();
    }

    // Normalize to local midnight to avoid timezone/date-shift issues when comparing dates
    dateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);

    return HabitInstanceModel(
      id: id,
      habitId: data['habitId'] ?? '',
      userId: data['userId'] ?? '',
      date: dateTime,
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'habitId': habitId, 'userId': userId, 'date': Timestamp.fromDate(date), 'completed': completed};
  }
}
