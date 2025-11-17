import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  static const String routeName = "/settings";

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.settings_rounded, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Section
                Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 12.h),
                _settingsCard(
                  context,
                  children: [
                    _settingsTile(
                      context,
                      icon: Icons.person_rounded,
                      title: 'Profile',
                      subtitle: user?.email ?? 'Not signed in',
                      onTap: () => context.go('/profile'),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _settingsTile(
                      context,
                      icon: Icons.email_rounded,
                      title: 'Email',
                      subtitle: user?.email ?? 'No email',
                      onTap: () {},
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Preferences Section
                Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 12.h),
                _settingsCard(
                  context,
                  children: [
                    SwitchListTile(
                      secondary: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.notifications_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20.sp,
                        ),
                      ),
                      title: Text(
                        'Notifications',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
                      ),
                      subtitle: Text(
                        'Get reminders for your habits',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                      ),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    SwitchListTile(
                      secondary: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.dark_mode_rounded,
                          color: Colors.orange,
                          size: 20.sp,
                        ),
                      ),
                      title: Text(
                        'Dark Mode',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
                      ),
                      subtitle: Text(
                        'Switch to dark theme',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                      ),
                      value: _darkModeEnabled,
                      onChanged: (value) {
                        setState(() => _darkModeEnabled = value);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // App Section
                Text(
                  'App',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 12.h),
                _settingsCard(
                  context,
                  children: [
                    _settingsTile(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get help with the app',
                      onTap: () {},
                      color: Colors.blue,
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _settingsTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      subtitle: 'App version and info',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('About'),
                            content: const Text('Habit Tracker App\nVersion 1.0.0'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      color: Colors.grey,
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _settingsTile(
                      context,
                      icon: Icons.privacy_tip_rounded,
                      title: 'Privacy Policy',
                      subtitle: 'Read our privacy policy',
                      onTap: () {},
                      color: Colors.purple,
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsCard(BuildContext context, {required List<Widget> children}) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}
