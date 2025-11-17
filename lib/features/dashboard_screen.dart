import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💡 Daily suggestion sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.insights, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: 'Get Daily Suggestion',
              onPressed: _requestDailySuggestion,
            ),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final isDesktop = constraints.maxWidth >= 600;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== Dashboard Summary Cards =====
                          Row(
                            children: [
                              Expanded(
                                child: _dashboardCard(
                                  context,
                                  Icons.list_alt_rounded,
                                  "Total Habits",
                                  totalHabits.toString(),
                                  const Color(0xFF667EEA),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _dashboardCard(
                                  context,
                                  Icons.check_circle_rounded,
                                  "Today",
                                  completedToday.toString(),
                                  const Color(0xFF51CF66),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _dashboardCard(
                                  context,
                                  Icons.local_fire_department_rounded,
                                  "Streak",
                                  totalStreak.toString(),
                                  const Color(0xFFFF6B6B),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          // ===== AI Daily Summary =====
                          _dailySummaryCard(),
                          SizedBox(height: 16.h),

                          // ===== Filter Chips & Completion Rate =====
                          isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Wrap(
                                      spacing: 8.w,
                                      children: [
                                        _buildFilterChip(
                                          '7 Days',
                                          _rangeDays == 7,
                                          () => setState(() => _rangeDays = 7),
                                        ),
                                        _buildFilterChip(
                                          '30 Days',
                                          _rangeDays == 30,
                                          () => setState(() => _rangeDays = 30),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    _completionRateCard(context, instances, habits, _rangeDays),
                                  ],
                                )
                              : Row(
                                  children: [
                                    _buildFilterChip('7 Days', _rangeDays == 7, () => setState(() => _rangeDays = 7)),
                                    SizedBox(width: 8.w),
                                    _buildFilterChip(
                                      '30 Days',
                                      _rangeDays == 30,
                                      () => setState(() => _rangeDays = 30),
                                    ),
                                    const Spacer(),
                                    _completionRateCard(context, instances, habits, _rangeDays),
                                  ],
                                ),
                          SizedBox(height: 24.h),

                          // ===== Completion Heatmap (Streak Style) =====
                          if (habits.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Icons.calendar_month,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  "Last 7 Days Activity",
                                  style: TextStyle(fontSize: isMobile ? 16.sp : 18.sp, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            _buildWeeklyHeatmap(context, instances, habits),
                            SizedBox(height: 24.h),
                          ],

                          // ===== Insights Card =====
                          _buildInsightsCard(context, habits, instances),
                          SizedBox(height: 24.h),

                          // ===== Habit List Section =====
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  Icons.list_alt_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                "Your Habits",
                                style: TextStyle(fontSize: isMobile ? 18.sp : 20.sp, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          if (habits.isEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.h),
                                child: Column(
                                  children: [
                                    Icon(Icons.add_task_rounded, size: 64.sp, color: Colors.grey.shade400),
                                    SizedBox(height: 16.h),
                                    Text(
                                      "No habits added yet.",
                                      style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
                                    ),
                                    SizedBox(height: 12.h),
                                    ElevatedButton.icon(
                                      icon: Icon(Icons.add_rounded, size: 20.sp),
                                      label: Text("Add Habit", style: TextStyle(fontSize: 14.sp)),
                                      onPressed: () => context.push(AddHabitScreen.routeName),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Column(
                              children: habits.map((habit) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 12.w : 16.w,
                                      vertical: 8.h,
                                    ),
                                    leading: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.check_circle_outline,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: isMobile ? 20.sp : 24.sp,
                                        ),
                                        onPressed: () {
                                          context.read<HabitCubit>().addHabitInstance(habit.id, habit.userId);
                                        },
                                      ),
                                    ),
                                    title: Text(
                                      habit.title,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14.sp : 16.sp),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Icon(
                                          Icons.local_fire_department,
                                          size: isMobile ? 14.sp : 16.sp,
                                          color: Colors.orange.shade400,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          "${habit.streak} day streak",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: isMobile ? 12.sp : 13.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton(
                                      icon: Icon(Icons.more_vert, size: isMobile ? 20.sp : 24.sp),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red, size: 20.sp),
                                              SizedBox(width: 8.w),
                                              Text('Delete', style: TextStyle(fontSize: 14.sp)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          context.read<HabitCubit>().handleEvent(DeleteHabitEvent(habit.id));
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    );
                  },
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(AddHabitScreen.routeName);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Habit', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _dashboardCard(BuildContext context, IconData icon, String title, String value, Color color) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 14.w : 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8.w : 10.w),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(icon, color: color, size: isMobile ? 20.sp : 24.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(fontSize: isMobile ? 20.sp : 24.sp, fontWeight: FontWeight.bold, color: color),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isMobile ? 11.sp : 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14.w : 16.w, vertical: isMobile ? 6.h : 8.h),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade700,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: isMobile ? 13.sp : 14.sp,
            ),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summary generated successfully!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingSummary = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _dailySummaryCard() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16.w : 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Daily Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16.sp : 18.sp),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: IconButton(
                  icon: _isGeneratingSummary
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded),
                  onPressed: _isGeneratingSummary ? null : _generateSummary,
                  tooltip: 'Generate new summary',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (_currentSummary != null)
            Container(
              padding: EdgeInsets.all(isMobile ? 14.w : 16.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
              child: Text(_currentSummary!, style: TextStyle(fontSize: isMobile ? 13.sp : 14.sp, height: 1.5)),
            )
          else
            Container(
              padding: EdgeInsets.all(isMobile ? 16.w : 20.w),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
              child: Column(
                children: [
                  Icon(Icons.auto_awesome_outlined, size: isMobile ? 40.sp : 48.sp, color: Colors.grey.shade400),
                  SizedBox(height: 12.h),
                  Text(
                    'No AI daily summary yet.',
                    style: TextStyle(fontSize: isMobile ? 13.sp : 14.sp, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Click generate to get your personalized summary!',
                    style: TextStyle(fontSize: isMobile ? 11.sp : 12.sp, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: _isGeneratingSummary ? null : _generateSummary,
                    icon: Icon(Icons.auto_awesome, size: isMobile ? 18.sp : 20.sp),
                    label: Text('Generate Summary', style: TextStyle(fontSize: isMobile ? 13.sp : 14.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20.w : 24.w,
                        vertical: isMobile ? 10.h : 12.h,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _completionRateCard(
    BuildContext context,
    List<HabitInstanceModel> instances,
    List<HabitModel> habits,
    int days,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
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
      padding: EdgeInsets.all(isMobile ? 12.w : 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: isMobile ? 45.h : 50.h,
            width: isMobile ? 45.w : 50.w,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: rate,
                  strokeWidth: isMobile ? 5 : 6,
                  backgroundColor: Colors.grey.shade200,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                Center(
                  child: Text(
                    '${(rate * 100).round()}%',
                    style: TextStyle(
                      fontSize: isMobile ? 10.sp : 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isMobile ? 12.w : 16.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Completion Rate',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12.sp : 14.sp,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$completed of $opportunities in $days days',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 10.sp : 12.sp),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Weekly heatmap showing daily completion activity
  Widget _buildWeeklyHeatmap(BuildContext context, List<HabitInstanceModel> instances, List<HabitModel> habits) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Calculate stats
    int bestDay = 0;
    int totalCompletions = 0;
    String bestDayName = '';

    for (var date in days) {
      final completedCount = instances.where((i) {
        return i.completed &&
            i.date.year == date.year &&
            i.date.month == date.month &&
            i.date.day == date.day;
      }).length;
      totalCompletions += completedCount;
      if (completedCount > bestDay) {
        bestDay = completedCount;
        bestDayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7];
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with description
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary, size: 16.sp),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Activity Heatmap',
                            style: TextStyle(fontSize: isMobile ? 13.sp : 14.sp, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Shows daily habit completions: darker = more habits completed',
                            style: TextStyle(fontSize: isMobile ? 9.sp : 10.sp, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // Main heatmap grid
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: days.map((date) {
                    final completedCount = instances.where((i) {
                      return i.completed &&
                          i.date.year == date.year &&
                          i.date.month == date.month &&
                          i.date.day == date.day;
                    }).length;

                    final dayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7];
                    final isToday = date.day == today.day && date.month == today.month && date.year == today.year;
                    final intensity = (completedCount / (habits.isNotEmpty ? habits.length : 1)).clamp(0.0, 1.0);
                    
                    // Enhanced color gradient
                    final color = intensity == 0
                        ? Colors.grey.shade100
                        : Color.lerp(
                            Theme.of(context).colorScheme.primary.withOpacity(0.25),
                            Theme.of(context).colorScheme.primary,
                            intensity,
                          )!;

                    return Tooltip(
                      message: '$completedCount of ${habits.length} completed',
                      child: Column(
                        children: [
                          Container(
                            width: isMobile ? 36.w : 45.w,
                            height: isMobile ? 36.w : 45.w,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10.r),
                              border: isToday
                                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2.5)
                                  : Border.all(color: Colors.grey.shade300, width: 1),
                              boxShadow: isToday
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  completedCount.toString(),
                                  style: TextStyle(
                                    fontSize: isMobile ? 13.sp : 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: intensity > 0.5 ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  '/${habits.length}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 8.sp : 9.sp,
                                    color: intensity > 0.5 ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: isMobile ? 10.sp : 11.sp,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontSize: isMobile ? 8.sp : 9.sp,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // Legend and stats
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              children: [
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Intensity:', style: TextStyle(fontSize: isMobile ? 10.sp : 11.sp, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        _legacyColorBox(Colors.grey.shade100, 6.w, 'None'),
                        SizedBox(width: 6.w),
                        _legacyColorBox(Theme.of(context).colorScheme.primary.withOpacity(0.25), 6.w, 'Low'),
                        SizedBox(width: 6.w),
                        _legacyColorBox(Theme.of(context).colorScheme.primary.withOpacity(0.6), 6.w, 'Mid'),
                        SizedBox(width: 6.w),
                        _legacyColorBox(Theme.of(context).colorScheme.primary, 6.w, 'High'),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _heatmapStat(
                        context,
                        icon: Icons.emoji_events,
                        label: 'Best Day',
                        value: bestDayName,
                        subtitle: '$bestDay completions',
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _heatmapStat(
                        context,
                        icon: Icons.check_circle,
                        label: 'This Week',
                        value: totalCompletions.toString(),
                        subtitle: 'total completions',
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _heatmapStat(
                        context,
                        icon: Icons.trending_up,
                        label: 'Avg/Day',
                        value: (totalCompletions ~/ 7).toString(),
                        subtitle: 'per day average',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legacyColorBox(Color color, double size, String label) {
    return Column(
      children: [
        Container(
          width: size * 2,
          height: size * 2,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.r), border: Border.all(color: Colors.grey.shade300, width: 0.5)),
        ),
        SizedBox(height: 3.h),
        Text(label, style: TextStyle(fontSize: 7.sp, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _heatmapStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 8.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // Insights card with recommendations
  Widget _buildInsightsCard(BuildContext context, List<HabitModel> habits, List<HabitInstanceModel> instances) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // Find best habit (highest streak)
    final bestHabit = habits.isNotEmpty ? habits.reduce((a, b) => a.streak > b.streak ? a : b) : null;
    
    // Calculate average streak
    final avgStreak = habits.isNotEmpty ? (habits.fold<int>(0, (sum, h) => sum + h.streak) / habits.length).round() : 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.08),
            Theme.of(context).colorScheme.tertiary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Quick Insights',
                style: TextStyle(fontSize: isMobile ? 14.sp : 16.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (bestHabit != null)
            _insightRow(
              context,
              icon: Icons.emoji_events,
              label: 'Best Habit',
              value: bestHabit.title,
              subtitle: '${bestHabit.streak} day streak 🔥',
              color: Colors.amber,
            )
          else
            _insightRow(
              context,
              icon: Icons.add_circle,
              label: 'Get Started',
              value: 'Add your first habit',
              subtitle: 'Create a habit to begin tracking',
              color: Colors.blue,
            ),
          SizedBox(height: 10.h),
          _insightRow(
            context,
            icon: Icons.trending_up,
            label: 'Avg Streak',
            value: '$avgStreak days',
            subtitle: 'Average across all habits',
            color: Colors.green,
          ),
          SizedBox(height: 10.h),
          _insightRow(
            context,
            icon: Icons.calendar_today,
            label: 'Total Habits',
            value: '${habits.length}',
            subtitle: 'Active habits being tracked',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _insightRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8.r)),
          child: Icon(icon, color: color, size: 16.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
