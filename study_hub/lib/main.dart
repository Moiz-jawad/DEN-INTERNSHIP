import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'features/onboarding/onboarding_flow.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_shell.dart';
import 'features/quiz/quiz_screen.dart';
import 'features/quiz/history_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/profile/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(prefs: prefs)),
      ],
      child: const StudyHubApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  AppState({required this.prefs});

  static const String onboardingKey = 'hasSeenOnboarding';

  bool get hasSeenOnboarding => prefs.getBool(onboardingKey) ?? false;
  Future<void> setHasSeenOnboarding() async {
    await prefs.setBool(onboardingKey, true);
    notifyListeners();
  }
}

class StudyHubApp extends StatefulWidget {
  const StudyHubApp({super.key});

  @override
  State<StudyHubApp> createState() => _StudyHubAppState();
}

class _StudyHubAppState extends State<StudyHubApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return GoRouter(
      debugLogDiagnostics: false,
      refreshListenable:
          GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
      redirect: (context, state) {
        final appState = Provider.of<AppState>(context, listen: false);
        final bool loggedIn = FirebaseAuth.instance.currentUser != null;
        final bool isOnboardingRoute = state.fullPath == '/onboarding';
        final bool isAuthRoute = state.fullPath?.startsWith('/auth') == true;

        if (!appState.hasSeenOnboarding && !isOnboardingRoute) {
          return '/onboarding';
        }
        if (appState.hasSeenOnboarding && !loggedIn && !isAuthRoute) {
          return '/auth/login';
        }
        if (loggedIn && (isAuthRoute || isOnboardingRoute)) {
          return '/home/quiz';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingFlow()),
        GoRoute(
          path: '/auth/login',
          builder: (c, s) => const LoginScreen(),
          routes: [
            GoRoute(path: '../register', redirect: (_, __) => '/auth/register'),
          ],
        ),
        GoRoute(
            path: '/auth/register', builder: (c, s) => const RegisterScreen()),
        ShellRoute(
          builder: (context, state, child) => HomeShell(child: child),
          routes: [
            GoRoute(
                path: '/home/quiz',
                builder: (c, s) => const QuizScreen(),
                routes: [
                  GoRoute(
                      path: 'history',
                      builder: (c, s) => const QuizHistoryScreen()),
                ]),
            GoRoute(
                path: '/home/tasks', builder: (c, s) => const TasksScreen()),
            GoRoute(path: '/home/chat', builder: (c, s) => const ChatScreen()),
            GoRoute(
                path: '/home/profile',
                builder: (c, s) => const ProfileScreen()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Study Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _notifySub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _notifySub;
  @override
  void dispose() {
    _notifySub.cancel();
    super.dispose();
  }
}
