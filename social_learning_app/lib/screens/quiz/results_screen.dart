// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/app_state.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';

class ResultsScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final String quizTitle;
  final String quizId;

  const ResultsScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.quizTitle,
    required this.quizId,
  });

  @override
  Widget build(BuildContext context) {
    // Get arguments and validate them
    final args = ModalRoute.of(context)?.settings.arguments;

    // Handle different argument types gracefully
    int finalScore = score;
    int finalTotalQuestions = totalQuestions;
    String finalQuizTitle = quizTitle;
    String finalQuizId = quizId;

    // If arguments are passed as a Map, use those instead
    if (args is Map<String, dynamic>) {
      finalScore = args['score'] ?? score;
      finalTotalQuestions = args['totalQuestions'] ?? totalQuestions;
      finalQuizTitle = args['quizTitle'] ?? quizTitle;
      finalQuizId = args['quizId'] ?? quizId;
    }

    // Validate input data
    if (finalTotalQuestions <= 0) {
      return _buildErrorScreen(
        context,
        'Invalid quiz data: Total questions must be greater than 0',
      );
    }

    if (finalScore < 0 || finalScore > finalTotalQuestions) {
      return _buildErrorScreen(
        context,
        'Invalid score data: Score must be between 0 and $finalTotalQuestions',
      );
    }

    final percentage = (finalScore / finalTotalQuestions) * 100;
    final isPassed = percentage >= 80;
    final performance = _getPerformanceLevel(percentage);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quiz Results'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Score Circle
            _buildScoreCircle(
              context,
              percentage,
              isPassed,
              finalScore,
              finalTotalQuestions,
            ),

            const SizedBox(height: 32),

            // Performance Message
            _buildPerformanceMessage(performance, isPassed),

            const SizedBox(height: 24),

            // Score Details
            _buildScoreDetails(
              context,
              finalQuizTitle,
              finalScore,
              finalTotalQuestions,
            ),

            const SizedBox(height: 32),

            // Performance Stats
            _buildPerformanceStats(context, percentage),

            const SizedBox(height: 40),

            // Action Buttons
            _buildActionButtons(
              context,
              finalQuizId,
              finalQuizTitle,
              finalScore,
              finalTotalQuestions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCircle(
    BuildContext context,
    double percentage,
    bool isPassed,
    int finalScore,
    int finalTotalQuestions,
  ) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPassed
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.orange.shade400, Colors.orange.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? Colors.green : Colors.orange).withValues(
              alpha: 0.3,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '$finalScore/$finalTotalQuestions',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMessage(String performance, bool isPassed) {
    return Column(
      children: [
        Text(
          performance,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isPassed ? Colors.green.shade700 : Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isPassed
              ? 'Excellent work! You\'ve mastered this topic.'
              : 'Good effort! Keep practicing to improve.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScoreDetails(
    BuildContext context,
    String finalQuizTitle,
    int finalScore,
    int finalTotalQuestions,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow('Quiz Title', finalQuizTitle, Icons.quiz),
          const Divider(height: 24),
          _buildDetailRow(
            'Questions Answered',
            '$finalTotalQuestions',
            Icons.question_answer,
          ),
          const Divider(height: 24),
          _buildDetailRow('Correct Answers', '$finalScore', Icons.check_circle),
          const Divider(height: 24),
          _buildDetailRow(
            'Accuracy',
            '${((finalScore / finalTotalQuestions) * 100).toStringAsFixed(1)}%',
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceStats(BuildContext context, double percentage) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Performance',
            _getPerformanceEmoji(percentage),
            _getPerformanceColor(percentage),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Status',
            percentage >= 80 ? 'PASSED' : 'NEEDS WORK',
            percentage >= 80 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    String finalQuizId,
    String finalQuizTitle,
    int finalScore,
    int finalTotalQuestions,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _saveResultAndNavigate(
              context,
              finalQuizId,
              finalQuizTitle,
              finalScore,
              finalTotalQuestions,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Save Result & Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              // Navigate to quiz history (will be implemented)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quiz History coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
              side: BorderSide(color: Colors.blue.shade600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'View Quiz History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 16),

        TextButton(
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: Text(
            'Back to Quizzes',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveResultAndNavigate(
    BuildContext context,
    String finalQuizId,
    String finalQuizTitle,
    int finalScore,
    int finalTotalQuestions,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('Starting to save quiz result...');

      // Validate user authentication
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      print('User authenticated: $userId');

      // Get additional data from arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final timeSpent = args?['timeSpent'] ?? 0;
      final quizCategory = args?['quizCategory'] ?? 'General';
      final difficulty = args?['difficulty'] ?? 'Medium';
      final questionAttempts =
          args?['questionAttempts'] as List<Map<String, dynamic>>? ?? [];
      final accuracy = args?['accuracy'] as double? ?? 0.0;
      final correctAnswers = args?['correctAnswers'] as int? ?? finalScore;
      final wrongAnswers =
          args?['wrongAnswers'] as int? ?? (finalTotalQuestions - finalScore);
      final skippedQuestions = args?['skippedQuestions'] ?? 0;
      final performanceMetrics =
          args?['performanceMetrics'] as Map<String, dynamic>?;

      print(
        'Quiz data prepared: timeSpent=$timeSpent, category=$quizCategory, difficulty=$difficulty',
      );

      // Get current user info
      final currentUser = AuthService.currentUser;
      final userName = currentUser?.displayName ?? 'User';
      final userEmail = currentUser?.email ?? '';
      print('User info: name=$userName, email=$userEmail');

      // Save to Firebase with retry logic
      bool firebaseSaved = false;
      int retryCount = 0;
      const maxRetries = 3;

      print('Attempting to save to Firebase...');

      while (!firebaseSaved && retryCount < maxRetries) {
        try {
          await FirebaseService.saveQuizAttempt(
            userId: userId,
            quizId: finalQuizId,
            quizTitle: finalQuizTitle,
            score: finalScore,
            totalQuestions: finalTotalQuestions,
            completedAt: DateTime.now(),
            timeSpent: timeSpent,
            userName: userName,
            userEmail: userEmail,
            questionAttempts: questionAttempts,
            quizCategory: quizCategory,
            difficulty: difficulty,
            accuracy: accuracy,
            correctAnswers: correctAnswers,
            wrongAnswers: wrongAnswers,
            skippedQuestions: skippedQuestions,
            performanceMetrics: performanceMetrics,
          );
          firebaseSaved = true;
          print('Firebase save successful on attempt ${retryCount + 1}');
        } catch (e) {
          retryCount++;
          print('Firebase save attempt $retryCount failed: $e');
          if (retryCount >= maxRetries) {
            throw Exception(
              'Failed to save to Firebase after $maxRetries attempts: $e',
            );
          }
          // Wait before retry
          await Future.delayed(Duration(seconds: retryCount));
        }
      }

      print('Saving to local state...');

      // Save to local state
      final appState = Provider.of<AppState>(context, listen: false);
      final result = QuizResult(
        quizId: finalQuizId,
        quizTitle: finalQuizTitle,
        score: finalScore,
        totalQuestions: finalTotalQuestions,
        completedAt: DateTime.now(),
      );

      await appState.addQuizResult(result);
      print('Local state save successful');

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Quiz result saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Navigate to quiz history after a short delay
      if (context.mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/history');
          }
        });
      }
    } catch (e) {
      print('Error in _saveResultAndNavigate: $e');
      print('Stack trace: ${StackTrace.current}');

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show error message with retry option
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save Failed'),
            content: Text('Failed to save quiz result: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveResultAndNavigate(
                    context,
                    finalQuizId,
                    finalQuizTitle,
                    finalScore,
                    finalTotalQuestions,
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  String _getPerformanceLevel(double percentage) {
    if (percentage >= 90) return 'Outstanding!';
    if (percentage >= 80) return 'Excellent!';
    if (percentage >= 70) return 'Good Job!';
    if (percentage >= 60) return 'Not Bad!';
    if (percentage >= 50) return 'Keep Trying!';
    return 'Need Practice';
  }

  String _getPerformanceEmoji(double percentage) {
    if (percentage >= 90) return '🏆';
    if (percentage >= 80) return '🎯';
    if (percentage >= 70) return '👍';
    if (percentage >= 60) return '😊';
    if (percentage >= 50) return '🤔';
    return '📚';
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 90) return Colors.purple;
    if (percentage >= 80) return Colors.green;
    if (percentage >= 70) return Colors.blue;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 50) return Colors.amber;
    return Colors.red;
  }
}
