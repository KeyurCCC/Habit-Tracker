import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_model.dart';
import '../models/habit_instance_model.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<HabitModel>> getHabits(String userId) async {
    final snapshot = await _firestore.collection('habits').where('userId', isEqualTo: userId).get();

    return snapshot.docs.map((doc) => HabitModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<HabitInstanceModel>> getHabitInstances(String userId) async {
    final habitsSnapshot = await _firestore.collection('habits').where('userId', isEqualTo: userId).get();

    final List<HabitInstanceModel> allInstances = [];

    for (var habitDoc in habitsSnapshot.docs) {
      final instancesSnapshot = await habitDoc.reference.collection('instances').get();

      for (var instanceDoc in instancesSnapshot.docs) {
        final data = instanceDoc.data();
        data['habitId'] = habitDoc.id;
        data['userId'] = userId;
        allInstances.add(HabitInstanceModel.fromMap(data, instanceDoc.id));
      }
    }

    return allInstances;
  }
}
