import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  const ResultScreen({super.key, required this.score});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    // Play confetti only if score is 20 or more
    if (widget.score >= 20) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String getResultMessage(int score) {
    if (score >= 40) return '🎓 Genius!';
    if (score >= 30) return '🌟 Above Average';
    if (score >= 20) return '🙂 Average';
    return '🔍 Keep Practicing';
  }

  Widget buildConfetti() {
    if (widget.score < 20) return const SizedBox.shrink();

    double emission = widget.score >= 40
        ? 0.1
        : widget.score >= 30
        ? 0.05
        : 0.02;

    int particles = widget.score >= 40
        ? 40
        : widget.score >= 30
        ? 20
        : 10;

    double maxForce = widget.score >= 40
        ? 30
        : widget.score >= 30
        ? 20
        : 10;

    double minForce = widget.score >= 40
        ? 15
        : widget.score >= 30
        ? 10
        : 5;

    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirection: pi / 2,
        emissionFrequency: emission,
        numberOfParticles: particles,
        maxBlastForce: maxForce,
        minBlastForce: minForce,
        gravity: 0.2,
        shouldLoop: false,
        colors: const [Colors.pink, Colors.blue, Colors.orange],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/quiz_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Liquid Glass Blur Overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(color: Colors.white.withOpacity(0.08)),
          ),

          // Confetti Animation
          buildConfetti(),

          // Result UI
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Your Final Score:',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${widget.score}/50',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                    shadows: [
                      Shadow(
                        blurRadius: 12,
                        color: Colors.purple.withOpacity(0.4),
                        offset: const Offset(2, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  getResultMessage(widget.score),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to quiz or home screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    foregroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 10,
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
