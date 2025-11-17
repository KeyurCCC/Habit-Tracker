import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pwa_demo/utils/router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'features/home_screen.dart';
import 'features/profile_screen.dart';
import 'features/settings_screen.dart';
import 'features/habits/cubits/habit_cubit.dart';
import 'firebase_options.dart';
import 'widgets/bottom_nav.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  usePathUrlStrategy();
  await NotificationService.initialize();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyPwaApp());
}

class MyPwaApp extends StatelessWidget {
  const MyPwaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HabitCubit>(
      create: (context) => HabitCubit(firestoreService: FirestoreService()),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;

          final Size designSize;

          if (width < 600) {
            designSize = const Size(360, 640);
          } else {
            designSize = const Size(1440, 900);
          }
          return ScreenUtilInit(
            designSize: designSize,
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              final baseScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0EA5E9));
              final colorScheme = baseScheme.copyWith(
                primary: const Color(0xFF0EA5E9), // blue/cyan
                secondary: const Color(0xFF10B981), // teal/green
                tertiary: const Color(0xFF22D3EE),
              );

              return MaterialApp.router(
                title: 'Flutter PWA + ScreenUtil Demo',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(useMaterial3: true, colorScheme: colorScheme),
                routerConfig: router,
              );
            },
            child: const ResponsiveHome(),
          );
        },
      ),
    );
  }
}

class ResponsiveHome extends StatefulWidget {
  const ResponsiveHome({super.key});
  static const String routeName = "/home";

  @override
  State<ResponsiveHome> createState() => _ResponsiveHomeState();
}

class _ResponsiveHomeState extends State<ResponsiveHome> {
  int _index = 0;

  final List<Widget> _pages = const [HomeScreen(), ProfileScreen(), SettingsScreen()];

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _token;

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);

      print('User granted permission: ${settings.authorizationStatus}');

      // Get the FCM token
      _token = await _messaging.getToken(
        vapidKey: "BMqR_hlD_J87qOeSXLBP_fZleNy_-BaqKOXUJVcL9is1nUJSwZz6FOJ8kUsP01XtcH4tdVR3yqumUJMgilwm4jQ",
      );
      print('FCM Token: $_token');

      if (_token != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fcmToken': _token,
          }, SetOptions(merge: true));
        }
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message received: ${message.notification?.title}');
        if (message.notification != null) {
          final notification = message.notification!;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(title: Text(notification.title ?? ''), content: Text(notification.body ?? '')),
          );
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter PWA Responsive', style: TextStyle(fontSize: 20.sp)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 200.w,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              child: Column(
                children: [
                  SizedBox(height: 40.h),
                  Text(
                    '🌐 Menu',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildSidebarButton(Icons.home, "Home", 0),
                  _buildSidebarButton(Icons.person, "Profile", 1),
                  _buildSidebarButton(Icons.settings, "Settings", 2),
                ],
              ),
            ),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: _pages[_index],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : BottomNav(index: _index, onTap: (i) => setState(() => _index = i)),
    );
  }

  Widget _buildSidebarButton(IconData icon, String label, int index) {
    final selected = _index == index;
    return InkWell(
      onTap: () => setState(() => _index = index),
      child: Container(
        color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : Colors.transparent,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        child: Row(
          children: [
            Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : Colors.black54, size: 22.sp),
            SizedBox(width: 10.w),
            Text(
              label,
              style: TextStyle(fontSize: 16.sp, color: selected ? Theme.of(context).colorScheme.primary : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
