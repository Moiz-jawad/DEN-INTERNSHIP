// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../services/ad_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentQuestion = 0;
  int _totalScore = 0;
  int _timeLeft = 10;
  double _progress = 1.0;
  Timer? _timer;
  bool _isOptionTapped = false;
  late DateTime _quizStartTime;
  late DateTime _questionStartTime; // Track when question started
  final int _timeLimit = 10;
  final Map<int, String> _selectedAnswers = {};
  final Map<int, int> _questionTimeSpent = {};
  final Map<int, bool> _questionCorrectness = {};
  final List<Map<String, dynamic>> _questionAttempts = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<AnimationController> _optionControllers = [];
  final List<Animation<Offset>> _optionAnimations = [];

  // Sample questions for demonstration - in production this would come from Firebase
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What is Flutter?',
      'answers': [
        {'text': 'A programming language', 'score': 0},
        {'text': 'A UI framework', 'score': 1},
        {'text': 'A database', 'score': 0},
        {'text': 'An operating system', 'score': 0},
      ],
    },
    {
      'question': 'Which programming language does Flutter use?',
      'answers': [
        {'text': 'Java', 'score': 0},
        {'text': 'Kotlin', 'score': 0},
        {'text': 'Dart', 'score': 1},
        {'text': 'Swift', 'score': 0},
      ],
    },
    {
      'question': 'What is the main function in Dart?',
      'answers': [
        {'text': 'start()', 'score': 0},
        {'text': 'main()', 'score': 1},
        {'text': 'begin()', 'score': 0},
        {'text': 'init()', 'score': 0},
      ],
    },
    {
      'question': 'What is a Widget in Flutter?',
      'answers': [
        {'text': 'A database table', 'score': 0},
        {'text': 'A UI component', 'score': 1},
        {'text': 'A network protocol', 'score': 0},
        {'text': 'A file format', 'score': 0},
      ],
    },
    {
      'question': 'How do you create a new Flutter project?',
      'answers': [
        {'text': 'flutter create project_name', 'score': 1},
        {'text': 'flutter new project_name', 'score': 0},
        {'text': 'flutter init project_name', 'score': 0},
        {'text': 'flutter start project_name', 'score': 0},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _quizStartTime = DateTime.now();
    _initializeAnimations();
    _startQuestion();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    for (int i = 0; i < 4; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      final animation = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

      _optionControllers.add(controller);
      _optionAnimations.add(animation);
    }
  }

  void _startQuestion() {
    _isOptionTapped = false;
    _timeLeft = 10;
    _progress = 1.0;
    _questionStartTime = DateTime.now(); // Track when question started

    _startTimer();
    _fadeController.forward(from: 0);
    _startOptionAnimations();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        _progress = _timeLeft / 10;
        if (_timeLeft <= 0) {
          _goToNextQuestion();
        }
      });
    });
  }

  void _startOptionAnimations() {
    for (int i = 0; i < _optionControllers.length; i++) {
      _optionControllers[i].reset();
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) _optionControllers[i].forward();
      });
    }
  }

  void _handleAnswer(int score) {
    if (_isOptionTapped || _timeLeft <= 0) return;
    _isOptionTapped = true;
    _totalScore += score;

    // Track the selected answer and time spent
    final question = questions[_currentQuestion];
    final answers = question['answers'] as List<Map<String, Object>>;
    final selectedAnswer =
        answers.firstWhere((a) => a['score'] == score)['text'] as String;
    final correctAnswer =
        answers.firstWhere((a) => a['score'] == 1)['text'] as String;

    _selectedAnswers[_currentQuestion] = selectedAnswer;
    _questionCorrectness[_currentQuestion] = score == 1;

    // Calculate time spent on this question
    final questionEndTime = DateTime.now();
    final timeSpent = questionEndTime.difference(_questionStartTime).inSeconds;
    _questionTimeSpent[_currentQuestion] = timeSpent;

    // Record question attempt details
    _questionAttempts.add({
      'questionIndex': _currentQuestion,
      'questionText': question['question'] as String,
      'selectedAnswer': selectedAnswer,
      'correctAnswer': correctAnswer,
      'isCorrect': score == 1,
      'timeSpent': timeSpent,
      'score': score,
      'maxScore': 1,
    });

    _goToNextQuestion();
  }

  void _goToNextQuestion() {
    _timer?.cancel();
    if (_currentQuestion < questions.length - 1) {
      setState(() {
        _currentQuestion++;
      });
      _startQuestion();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    final endTime = DateTime.now();
    final totalTime = endTime.difference(_quizStartTime).inSeconds;

    // Show interstitial ad without blocking the UI
    if (AdService.isInterstitialAdReady) {
      print('Showing interstitial ad...');
      AdService.showInterstitialAd(); // This is now non-blocking
    } else {
      print('Interstitial ad not ready, proceeding without ad');
    }

    // Navigate to results immediately
    Navigator.pushReplacementNamed(
      context,
      '/result',
      arguments: {
        'score': _totalScore,
        'totalQuestions': questions.length,
        'quizTitle': 'General Knowledge Quiz',
        'quizId': 'quiz_${DateTime.now().millisecondsSinceEpoch}',
        'totalTime': totalTime,
        'questionAttempts': _questionAttempts,
      },
    );
  }

  // Calculate difficulty level based on performance
  String _calculateDifficultyLevel(double percentage) {
    if (percentage >= 90) return 'Expert';
    if (percentage >= 80) return 'Advanced';
    if (percentage >= 70) return 'Intermediate';
    if (percentage >= 60) return 'Beginner';
    return 'Novice';
  }

  // Calculate time efficiency
  String _calculateTimeEfficiency(int timeSpent, int totalQuestions) {
    final avgTimePerQuestion = timeSpent / totalQuestions;
    if (avgTimePerQuestion <= 30) return 'Very Fast';
    if (avgTimePerQuestion <= 60) return 'Fast';
    if (avgTimePerQuestion <= 90) return 'Normal';
    if (avgTimePerQuestion <= 120) return 'Slow';
    return 'Very Slow';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safety check for questions array
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No questions available')),
      );
    }

    // Safety check for current question index
    if (_currentQuestion >= questions.length) {
      return const Scaffold(
        body: Center(child: Text('Question index out of bounds')),
      );
    }

    final question = questions[_currentQuestion];
    final answers = question['answers'] as List<Map<String, Object>>?;

    // Safety check for answers
    if (answers == null || answers.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No answers available for this question')),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/quiz_bg-pic.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Liquid Glass Effect (Blur + Transparent Overlay)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              color: Colors.white.withValues(
                alpha: 0.08,
              ), // adjust opacity for stronger glass feel
            ),
          ),

          // Quiz Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quiz ${_currentQuestion + 1}/${questions.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Score: $_totalScore',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4B63AC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Question Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question['question'] as String? ??
                                'Question not available',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '⏳ $_timeLeft seconds',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Options
                    Expanded(
                      child: ListView.builder(
                        itemCount: answers.length,
                        itemBuilder: (context, index) {
                          final answer = answers[index];
                          final answerText =
                              answer['text'] as String? ??
                              'Answer not available';
                          final answerScore = answer['score'] as int? ?? 0;

                          return SlideTransition(
                            position: _optionAnimations[index],
                            child: GlassOptionButton(
                              text: answerText,
                              onTap: () => _handleAnswer(answerScore),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ⬜ Reusable Elegant Glass Option Button
class GlassOptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const GlassOptionButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 60,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
