import 'package:flutter/material.dart';
import 'package:quiz_application/home_screen.dart';
import 'package:quiz_application/quiz_screen.dart';
import 'package:quiz_application/result_screen.dart';

void main() => runApp(const QuizApp());

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MCQ Quiz',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          backgroundColor: Color.fromRGBO(62, 87, 66, 0.86),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          case '/quiz':
            return MaterialPageRoute(
              builder: (_) => const QuizScreen(), // no score needed here
            );

          case '/result':
            final score = settings.arguments as int; // cast arguments to int
            return MaterialPageRoute(
              builder: (_) => ResultScreen(score: score),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('404 - Page Not Found')),
              ),
            );
        }
      },
    );
  }
}
