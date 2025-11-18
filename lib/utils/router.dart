import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pwa_demo/features/dashboard_screen.dart';
import 'package:flutter_pwa_demo/features/geminiChat/cubits/gemini_chat_cubit.dart';
import 'package:flutter_pwa_demo/features/geminiChat/screens/gemini_chat_screen.dart';
import 'package:flutter_pwa_demo/features/habits/cubits/habit_cubit.dart';
import 'package:flutter_pwa_demo/features/habits/screens/add_habit_screen.dart';
import 'package:flutter_pwa_demo/features/login/cubits/google_sign_in_cubit.dart';
import 'package:flutter_pwa_demo/features/login/screens/login_screen.dart';
import 'package:flutter_pwa_demo/features/settings/notification_settings_screen.dart';
import 'package:flutter_pwa_demo/features/settings/scheduled_notifications_screen.dart';
import 'package:flutter_pwa_demo/services/firestore_service.dart';
import 'package:go_router/go_router.dart';

import '../features/habits/screens/habit_list_screen.dart';
import '../features/home_screen.dart';
import '../features/profile_screen.dart';
import '../features/settings_screen.dart';
import '../main.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: HomeScreen.routeName,
      pageBuilder: (context, state) => NoTransitionPage(child: const HomeScreen()),
    ),
    GoRoute(
      path: ResponsiveHome.routeName,
      pageBuilder: (context, state) => NoTransitionPage(
        child: MultiBlocProvider(
          providers: [BlocProvider<GoogleSignInCubit>(create: (_) => GoogleSignInCubit())],
          child: const ResponsiveHome(),
        ),
      ),
    ),
    GoRoute(
      path: ProfileScreen.routeName,
      pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
    ),
    GoRoute(
      path: SettingsScreen.routeName,
      pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
    ),
    GoRoute(
      path: LoginScreen.routeName,
      pageBuilder: (context, state) => NoTransitionPage(
        child: MultiBlocProvider(
          providers: [BlocProvider<GoogleSignInCubit>(create: (_) => GoogleSignInCubit())],
          child: LoginScreen(),
        ),
      ),
    ),
    GoRoute(
      path: GeminiChatScreen.routeName,
      pageBuilder: (context, state) => NoTransitionPage(
        child: MultiBlocProvider(
          providers: [BlocProvider<GeminiChatCubit>(create: (_) => GeminiChatCubit())],
          child: GeminiChatScreen(),
        ),
      ),
    ),
    GoRoute(
      path: HabitListScreen.routeName,
      pageBuilder: (context, state) => NoTransitionPage(
        child: MultiBlocProvider(
          providers: [BlocProvider<HabitCubit>(create: (_) => HabitCubit(firestoreService: FirestoreService()))],
          child: HabitListScreen(),
        ),
      ),
    ),
    GoRoute(
      path: AddHabitScreen.routeName,
      pageBuilder: (context, state) => NoTransitionPage(
        child: MultiBlocProvider(
          providers: [BlocProvider<HabitCubit>(create: (_) => HabitCubit(firestoreService: FirestoreService()))],
          child: AddHabitScreen(),
        ),
      ),
    ),
    GoRoute(
      path: DashboardScreen.routeName,
      pageBuilder: (context, state) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        return NoTransitionPage(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<HabitCubit>(
                create: (_) => HabitCubit(firestoreService: FirestoreService())..loadDashboardData(userId!),
              ),
            ],
            child: DashboardScreen(),
          ),
        );
      },
    ),
    GoRoute(
      path: NotificationSettingsScreen.routeName,
      pageBuilder: (context, state) => const NoTransitionPage(child: NotificationSettingsScreen()),
    ),
    GoRoute(
      path: ScheduledNotificationsScreen.routeName,
      pageBuilder: (context, state) => NoTransitionPage(
        child: MultiBlocProvider(
          providers: [BlocProvider<HabitCubit>(create: (_) => HabitCubit(firestoreService: FirestoreService()))],
          child: const ScheduledNotificationsScreen(),
        ),
      ),
    ),
  ],
);
