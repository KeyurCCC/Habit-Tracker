import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/notification_preference.dart';
import '../../services/firestore_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  static const String routeName = "/notificationSettings";
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late final FirestoreService _firestoreService;
  late NotificationPreference _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final prefs = await _firestoreService.getNotificationPreference(userId);
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading preferences: $e')));
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await _firestoreService.setNotificationPreference(userId, _preferences);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Preferences saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectTime(BuildContext context, String label, int hour, int minute, Function(int, int) onPicked) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked != null) {
      onPicked(picked.hour, picked.minute);
      setState(() {});
    }
  }

  void _resetToDefaults() {
    setState(() {
      _preferences = NotificationPreference();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset to defaults')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Notification Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable/Disable toggle
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enable Reminders',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Get notified before your streaks end',
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Switch(
                          value: _preferences.enabledReminders,
                          onChanged: (val) {
                            setState(() => _preferences = _preferences.copyWith(enabledReminders: val));
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Evening Reminder Time
            if (_preferences.enabledReminders) ...[
              Text('Reminder Times', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              SizedBox(height: 12.h),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      // Evening reminder
                      _buildTimeRow(
                        context,
                        '🌙 Evening Reminder',
                        _preferences.eveningReminderHour,
                        _preferences.eveningReminderMinute,
                        () => _selectTime(
                          context,
                          'Evening Reminder',
                          _preferences.eveningReminderHour,
                          _preferences.eveningReminderMinute,
                          (h, m) => setState(() => _preferences = _preferences.copyWith(eveningReminderHour: h, eveningReminderMinute: m)),
                        ),
                      ),
                      Divider(height: 24.h),
                      // Late reminder
                      _buildTimeRow(
                        context,
                        '⏰ Final Reminder',
                        _preferences.lateReminderHour,
                        _preferences.lateReminderMinute,
                        () => _selectTime(
                          context,
                          'Final Reminder',
                          _preferences.lateReminderHour,
                          _preferences.lateReminderMinute,
                          (h, m) => setState(() => _preferences = _preferences.copyWith(lateReminderHour: h, lateReminderMinute: m)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],

            // Info box
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, size: 18.sp, color: Theme.of(context).colorScheme.primary),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Reminders are sent when you have a streak and haven\'t completed the habit today.',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _resetToDefaults,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePreferences,
                    icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(BuildContext context, String label, int hour, int minute, VoidCallback onTap) {
    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 16.sp, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 6.w),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
