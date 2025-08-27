// ignore_for_file: avoid_print, unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning_app/screens/auth/auth_wrapper.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'providers/task_provider.dart';
import 'providers/chat_provider.dart';
import 'services/firebase_service.dart';
import 'services/ad_service.dart';
import 'services/task_service.dart';
import 'config/realtime_database_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/quiz/results_screen.dart';
import 'screens/quiz/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with comprehensive error handling
  try {
    print('Initializing Firebase...');

    // Initialize Firebase for all platforms
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('Firebase initialized successfully');

    // Initialize Firestore
    final firestore = FirebaseFirestore.instance;
    print('Firestore initialized successfully');

    // Initialize Firebase Realtime Database
    try {
      print('Initializing Firebase Realtime Database...');
      RealtimeDatabaseConfig.initialize();
      print('Firebase Realtime Database initialized successfully');

      // Test database connection
      await TaskService.initializeDatabase();
    } catch (e) {
      print('Warning: Failed to initialize Firebase Realtime Database: $e');
      // Continue app initialization even if database fails
    }

    // Initialize Mobile Ads SDK
    try {
      print('Initializing Mobile Ads SDK...');
      await AdService.initialize();
      print('Mobile Ads SDK initialized successfully');
    } catch (e) {
      print('Warning: Failed to initialize Mobile Ads SDK: $e');
      // Continue app initialization even if ads fail
    }

    // Initialize sample quizzes in Firestore
    try {
      print('Initializing sample quizzes...');
      await FirebaseService.initializeSampleQuizzes();
      print('Sample quizzes initialized successfully');
    } catch (e) {
      print('Warning: Failed to initialize sample quizzes: $e');
      // Continue app initialization even if sample quizzes fail
    }
  } catch (e) {
    print('Critical: Firebase initialization failed: $e');
    print('App will continue with limited functionality');
    // Continue with app initialization even if Firebase fails
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => TaskProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Social Learning App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // fontFamily: 'Poppins', // Uncomment when fonts are added
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        home: AuthWrapper(),
        routes: {
          '/auth': (context) => const LoginScreen(),
          '/quiz': (context) => const QuizScreen(),
          '/history': (context) => const QuizHistoryScreen(),
          '/result': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>?;
            return ResultsScreen(
              score: args?['score'] ?? 0,
              totalQuestions: args?['totalQuestions'] ?? 10,
              quizTitle: args?['quizTitle'] ?? 'Quiz',
              quizId: args?['quizId'] ?? '',
            );
          },
        },
      ),
    );
  }
}
