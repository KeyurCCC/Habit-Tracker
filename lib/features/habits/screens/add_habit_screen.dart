import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_pwa_demo/features/dashboard_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cubits/habit_cubit.dart';
import '../cubits/habit_event.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  static const String routeName = "/addHabitScreen";

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _uuid = const Uuid();
  String _goalType = 'daily';
  int _targetCount = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Add Habit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g., Meditate', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description', hintText: 'Optional', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text('Goal Type'),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'daily', label: Text('Daily'), icon: Icon(Icons.calendar_today)),
                      ButtonSegment(value: 'weekly', label: Text('Weekly'), icon: Icon(Icons.date_range)),
                      ButtonSegment(value: 'custom', label: Text('Custom'), icon: Icon(Icons.tune)),
                    ],
                    selected: {_goalType},
                    onSelectionChanged: (set) {
                      setState(() => _goalType = set.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Text('Target Count')),
                      IconButton(
                        onPressed: () => setState(() => _targetCount = (_targetCount > 1) ? _targetCount - 1 : 1),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_targetCount'),
                      IconButton(
                        onPressed: () => setState(() => _targetCount = (_targetCount < 20) ? _targetCount + 1 : 20),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final userId = FirebaseAuth.instance.currentUser!.uid;
                        final id = _uuid.v4();

                        final habitData = {
                          'id': id,
                          'userId': userId,
                          'title': _titleController.text.trim(),
                          'description': _descController.text.trim(),
                          'goalType': _goalType,
                          'targetCount': _targetCount,
                          'completedCount': 0,
                          'streak': 0,
                          'lastCompletedAt': Timestamp.now(),
                          'createdAt': Timestamp.now(),
                        };

                        context.read<HabitCubit>().handleEvent(AddHabitEvent(habitData));
                        Router.neglect(context, () => context.pop());
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Habit'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
