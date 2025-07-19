import 'dart:async';
import 'dart:ui';

import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:quiz_application/question.dart';

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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<AnimationController> _optionControllers = [];
  final List<Animation<Offset>> _optionAnimations = [];

  @override
  void initState() {
    super.initState();
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
      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: _totalScore,
      );
    }
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
    final question = questions[_currentQuestion];
    final answers = question['answers'] as List<Map<String, Object>>;

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
              color: Colors.white.withOpacity(
                0.08,
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
                        color: Colors.white.withOpacity(0.9),
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
                            question['question'] as String,
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
                          return SlideTransition(
                            position: _optionAnimations[index],
                            child: GlassOptionButton(
                              text: answer['text'] as String,
                              onTap: () =>
                                  _handleAnswer(answer['score'] as int),
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
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
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
