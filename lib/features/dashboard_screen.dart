import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../models/habit_model.dart';
import '../../../models/habit_instance_model.dart';
import '../../../services/gemini_service.dart';
import '../../../services/daily_suggestion_service.dart';
import 'habits/cubits/habit_cubit.dart';
import 'habits/cubits/habit_event.dart';
import 'habits/cubits/habit_state.dart';
import 'habits/screens/add_habit_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = "/dashboardScreen";
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final String userId;
  int _rangeDays = 7; // 7 or 30
  bool _isGeneratingSummary = false;
  String? _currentSummary;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    context.read<HabitCubit>().handleEvent(LoadHabitsEvent(userId));
    
    // Auto-generate daily suggestion when dashboard loads (once per day)
    _checkAndSendDailySuggestion();
  }

  Future<void> _checkAndSendDailySuggestion() async {
    try {
      await DailySuggestionService.generateAndNotifyWithCheck();
    } catch (e) {
      // Fail silently - don't interrupt user experience
      print('Auto-suggestion error: $e');
    }
  }

  Future<void> _requestDailySuggestion() async {
    try {
      await DailySuggestionService.generateAndNotifyDailySuggestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('💡 Daily suggestion sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Habit Dashboard"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Get Daily Suggestion',
            onPressed: _requestDailySuggestion,
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<HabitCubit, HabitState>(
          builder: (context, state) {
            if (state is HabitLoadingState) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is HabitLoadedState) {
              final List<HabitModel> habits = state.habits;
              final List<HabitInstanceModel> instances = state.instances;

              final today = DateTime.now();

              // ✅ Calculate key dashboard metrics
              final totalHabits = habits.length;
              final completedToday = instances.where((i) {
                final d = i.date;
                return i.completed && d.year == today.year && d.month == today.month && d.day == today.day;
              }).length;
              final totalStreak = habits.fold(0, (sum, h) => sum + (h.streak));

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HabitCubit>().handleEvent(LoadHabitsEvent(userId));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== Dashboard Summary Cards =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _dashboardCard(Icons.list, "Habits", totalHabits),
                          _dashboardCard(Icons.check_circle, "Completed", completedToday),
                          _dashboardCard(Icons.local_fire_department, "Total Streak", totalStreak),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ===== AI Daily Summary =====
                      _dailySummaryCard(),
                      const SizedBox(height: 16),

                      // ===== Filter Chips & Completion Rate =====
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('7 Days'),
                            selected: _rangeDays == 7,
                            onSelected: (_) => setState(() => _rangeDays = 7),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('30 Days'),
                            selected: _rangeDays == 30,
                            onSelected: (_) => setState(() => _rangeDays = 30),
                          ),
                          const Spacer(),
                          _completionRateCard(instances, habits, _rangeDays),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ===== Streaks by Habit (Bar Chart) =====
                      if (habits.isNotEmpty) ...[
                        const Text(
                          "Streaks by Habit",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 220,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: BarChart(
                            BarChartData(
                              gridData: FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= habits.length) return const SizedBox.shrink();
                                      final title = habits[idx].title;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          title.length > 6 ? "${title.substring(0, 6)}…" : title,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                    reservedSize: 42,
                                  ),
                                ),
                              ),
                              barGroups: [
                                for (int i = 0; i < habits.length; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: habits[i].streak.toDouble(),
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 16,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ===== Habit List Section =====
                      const Text("Your Habits", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      if (habits.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              const Text("No habits added yet."),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text("Add Habit"),
                                onPressed: () => context.push(AddHabitScreen.routeName),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: habits.map((habit) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                  onPressed: () {
                                    context.read<HabitCubit>().addHabitInstance(habit.id, habit.userId);
                                  },
                                ),
                                title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  "Streak: ${habit.streak} days",
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    context.read<HabitCubit>().handleEvent(DeleteHabitEvent(habit.id));
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            }

            if (state is HabitErrorState) {
              return Center(child: Text("Error: ${state.message}"));
            }

            return const Center(child: Text("No data available."));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AddHabitScreen.routeName);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _dashboardCard(IconData icon, String title, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            const SizedBox(height: 8),
            Text(value.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isGeneratingSummary = true;
      _currentSummary = null; // Clear previous summary while generating
    });

    try {
      // Get current habits from state
      final state = context.read<HabitCubit>().state;
      if (state is! HabitLoadedState) {
        throw Exception('Please wait for habits to load');
      }

      final habits = state.habits;
      if (habits.isEmpty) {
        throw Exception('No habits found. Add some habits first!');
      }

      // Generate summary using Gemini (no Firestore save)
      final summary = await GeminiService.generateDailySummary(userId: userId, habits: habits);

      if (mounted) {
        setState(() {
          _currentSummary = summary;
          _isGeneratingSummary = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Summary generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingSummary = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _dailySummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🧠 AI Daily Summary',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: _isGeneratingSummary
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                onPressed: _isGeneratingSummary ? null : _generateSummary,
                tooltip: 'Generate new summary',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_currentSummary != null)
            Text(_currentSummary!)
          else
            Column(
              children: [
                const Text('No AI daily summary yet. Click generate to get your personalized summary!'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isGeneratingSummary ? null : _generateSummary,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate Summary'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _completionRateCard(List<HabitInstanceModel> instances, List<HabitModel> habits, int days) {
    final now = DateTime.now();
    final since = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final completed = instances.where((i) {
      if (!i.completed) return false;
      final d = DateTime(i.date.year, i.date.month, i.date.day);
      return d.isAfter(since.subtract(const Duration(days: 1))) && d.isBefore(now.add(const Duration(days: 1)));
    }).length;
    // Theoretical opportunities: each habit per day
    final opportunities = habits.length * days;
    final rate = opportunities == 0 ? 0.0 : (completed / opportunities);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            width: 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFE5E7EB),
                  color: Colors.teal,
                ),
                Center(child: Text('${(rate * 100).round()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Completion Rate', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$completed of $opportunities in $days days', style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
