// ignore_for_file: avoid_print, unnecessary_cast, avoid_types_as_parameter_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Public method to ensure user document exists (can be called from app state)
  static Future<bool> ensureUserDocumentExists(String userId) async {
    try {
      await _ensureUserDocumentExists(userId);
      return true;
    } catch (e) {
      print('Failed to ensure user document exists: $e');
      return false;
    }
  }

  // Public method to ensure user document exists with explicit user information
  static Future<bool> ensureUserDocumentExistsWithInfo(
    String userId, {
    String? name,
    String? email,
  }) async {
    try {
      await _ensureUserDocumentExistsWithInfo(userId, name: name, email: email);
      return true;
    } catch (e) {
      print('Failed to ensure user document exists with info: $e');
      return false;
    }
  }

  // Ensure user document exists with explicit user information
  static Future<void> _ensureUserDocumentExistsWithInfo(
    String userId, {
    String? name,
    String? email,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        // Use provided information or fallback to Firebase Auth
        final firebaseUser = _auth.currentUser;
        String userName = name ?? 'User';
        String userEmail = email ?? '';

        if (firebaseUser != null) {
          // If no name provided, try to get from Firebase Auth
          if (userName == 'User' &&
              firebaseUser.displayName != null &&
              firebaseUser.displayName!.isNotEmpty) {
            userName = firebaseUser.displayName!;
          }
          // If no email provided, use Firebase Auth email
          if (userEmail.isEmpty) {
            userEmail = firebaseUser.email ?? '';
          }
        }

        // Create user document with the best available information
        final userData = {
          'id': userId,
          'name': userName,
          'email': userEmail,
          'avatarUrl': firebaseUser?.photoURL,
          'quizHistory': [],
          'tasksCount': 0,
          'quizStatistics': {
            'totalQuizzes': 0,
            'totalScore': 0,
            'totalQuestions': 0,
            'averageScore': 0.0,
            'passedQuizzes': 0,
            'totalTimeSpent': 0,
            'bestScore': 0,
            'worstScore': 100,
            'totalCorrectAnswers': 0,
            'totalWrongAnswers': 0,
            'averageTimePerQuestion': 0.0,
            'quizCategories': {},
            'difficultyLevels': {},
            'lastQuizDate': null,
            'streakDays': 0,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(userId).set(userData);
        print(
          'Created user document for: $userId with name: $userName and email: $userEmail',
        );
      } else {
        // Document exists, update with provided information if different
        final data = userDoc.data()!;
        final currentName = data['name'] ?? 'User';
        final currentEmail = data['email'] ?? '';

        String newName = currentName;
        String newEmail = currentEmail;

        // Update with provided information if available
        if (name != null && name != currentName) {
          newName = name;
        }
        if (email != null && email != currentEmail) {
          newEmail = email;
        }

        // Also check Firebase Auth for updates
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          if (firebaseUser.displayName != null &&
              firebaseUser.displayName!.isNotEmpty &&
              firebaseUser.displayName != newName) {
            newName = firebaseUser.displayName!;
          }
          if (firebaseUser.email != null && firebaseUser.email != newEmail) {
            newEmail = firebaseUser.email!;
          }
        }

        // Update if there are changes
        if (newName != currentName || newEmail != currentEmail) {
          await _firestore.collection('users').doc(userId).update({
            'name': newName,
            'email': newEmail,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          print(
            'Updated user document with name: $newName and email: $newEmail',
          );
        }

        // Ensure required fields exist
        await _ensureRequiredFields(userId, data);
      }
    } catch (e) {
      print('Error ensuring user document exists with info: $e');
      rethrow;
    }
  }

  // Ensure required fields exist in user document
  static Future<void> _ensureRequiredFields(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final hasQuizStatistics = data.containsKey('quizStatistics');
      final hasQuizHistory = data.containsKey('quizHistory');

      if (!hasQuizStatistics || !hasQuizHistory) {
        final updates = <String, dynamic>{};

        if (!hasQuizStatistics) {
          updates['quizStatistics'] = {
            'totalQuizzes': 0,
            'totalScore': 0,
            'totalQuestions': 0,
            'averageScore': 0.0,
            'passedQuizzes': 0,
            'totalTimeSpent': 0,
            'bestScore': 0,
            'worstScore': 100,
            'totalCorrectAnswers': 0,
            'totalWrongAnswers': 0,
            'averageTimePerQuestion': 0.0,
            'quizCategories': {},
            'difficultyLevels': {},
            'lastQuizDate': null,
            'streakDays': 0,
          };
        }

        if (!hasQuizHistory) {
          updates['quizHistory'] = [];
        }

        if (updates.isNotEmpty) {
          updates['lastUpdated'] = FieldValue.serverTimestamp();
          await _firestore.collection('users').doc(userId).update(updates);
          print(
            'Updated existing user document with missing fields for: $userId',
          );
        }
      }
    } catch (e) {
      print('Error ensuring required fields: $e');
    }
  }

  // Update existing user document with correct information from Firebase Auth
  static Future<void> updateUserDocumentWithAuthInfo(String userId) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        final actualName = firebaseUser.displayName ?? 'User';
        final actualEmail = firebaseUser.email ?? '';

        await _firestore.collection('users').doc(userId).update({
          'name': actualName,
          'email': actualEmail,
          'avatarUrl': firebaseUser.photoURL,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        print(
          'Updated user document with correct info: name=$actualName, email=$actualEmail',
        );
      }
    } catch (e) {
      print('Error updating user document with auth info: $e');
    }
  }

  // Force update user document with correct information (can be called to fix existing users)
  static Future<void> forceUpdateUserDocument(String userId) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        // Get the best available name
        String userName = 'User';
        if (firebaseUser.displayName != null &&
            firebaseUser.displayName!.isNotEmpty) {
          userName = firebaseUser.displayName!;
        }

        final userEmail = firebaseUser.email ?? '';

        // Update the user document
        await _firestore.collection('users').doc(userId).update({
          'name': userName,
          'email': userEmail,
          'avatarUrl': firebaseUser.photoURL,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        print('Force updated user document: name=$userName, email=$userEmail');
      }
    } catch (e) {
      print('Error force updating user document: $e');
    }
  }

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get available quizzes
  static Future<List<Quiz>> getAvailableQuizzes() async {
    try {
      final quizzesRef = _firestore.collection('quizzes');
      final querySnapshot = await quizzesRef.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Quiz(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          questions:
              (data['questions'] as List<Object?>?)
                  ?.map(
                    (q) => Question(
                      id: (q as Map<String, dynamic>)['id'] ?? '',
                      questionText:
                          (q as Map<String, dynamic>)['question'] ?? '',
                      options: List<String>.from(
                        (q as Map<String, dynamic>)['options'] ?? [],
                      ),
                      correctAnswerIndex:
                          (q as Map<String, dynamic>)['correctAnswer'] ?? 0,
                      explanation:
                          (q as Map<String, dynamic>)['explanation'] ?? '',
                    ),
                  )
                  .toList() ??
              [],
          timeLimit: data['timeLimit'] ?? 30,
          category: data['category'] ?? 'General',
        );
      }).toList();
    } catch (e) {
      print('Error getting available quizzes: $e');
      return [];
    }
  }

  // Initialize sample quizzes
  static Future<void> initializeSampleQuizzes() async {
    try {
      final quizzesRef = _firestore.collection('quizzes');

      // Check if quizzes already exist
      final existingQuizzes = await quizzesRef.get();
      if (existingQuizzes.docs.isNotEmpty) {
        return; // Quizzes already exist
      }

      // Sample quiz data
      final sampleQuizzes = [
        {
          'title': 'Basic Math',
          'description': 'Test your basic math skills',
          'questions': [
            {
              'id': 'math_1',
              'question': 'What is 2 + 2?',
              'options': ['3', '4', '5', '6'],
              'correctAnswer': 1,
              'explanation': '2 + 2 equals 4',
            },
            {
              'id': 'math_2',
              'question': 'What is 5 × 3?',
              'options': ['12', '15', '18', '20'],
              'correctAnswer': 1,
              'explanation': '5 × 3 equals 15',
            },
          ],
          'timeLimit': 30,
          'category': 'Mathematics',
        },
      ];

      // Add quizzes to Firestore
      for (final quiz in sampleQuizzes) {
        await quizzesRef.add(quiz);
      }
    } catch (e) {
      print('Error initializing sample quizzes: $e');
    }
  }

  // Save quiz attempt with comprehensive data
  static Future<void> saveQuizAttempt({
    required String userId,
    required String quizId,
    required String quizTitle,
    required int score,
    required int totalQuestions,
    required DateTime completedAt,
    int timeSpent = 0,
    String? userName,
    String? userEmail,
    List<Map<String, dynamic>>? questionAttempts,
    String? quizCategory,
    String? difficulty,
    double? accuracy,
    int? correctAnswers,
    int? wrongAnswers,
    int? skippedQuestions,
    Map<String, dynamic>? performanceMetrics,
  }) async {
    try {
      print('Starting quiz attempt save for user: $userId');

      // First, ensure user document exists with retry logic
      print('Ensuring user document exists...');
      bool userDocumentReady = false;
      int retryCount = 0;
      const maxRetries = 3;

      while (!userDocumentReady && retryCount < maxRetries) {
        try {
          await _ensureUserDocumentExists(userId);
          userDocumentReady = true;
          print('User document ensured successfully');
        } catch (e) {
          retryCount++;
          print('Attempt $retryCount failed to ensure user document: $e');
          if (retryCount >= maxRetries) {
            throw Exception(
              'Failed to ensure user document exists after $maxRetries attempts: $e',
            );
          }
          // Wait before retry
          await Future.delayed(Duration(seconds: retryCount));
        }
      }

      // Verify user document exists before proceeding
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception(
          'User document still does not exist after creation attempts',
        );
      }
      print('User document verified successfully');

      // Calculate additional metrics
      final percentage = (score / totalQuestions) * 100;
      final isPassed = percentage >= 80;
      final finalCorrectAnswers = correctAnswers ?? score;
      final finalWrongAnswers = wrongAnswers ?? (totalQuestions - score);
      final finalAccuracy = accuracy ?? percentage;

      // Create comprehensive quiz attempt data
      final quizAttemptData = {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'quizId': quizId,
        'quizTitle': quizTitle,
        'quizCategory': quizCategory ?? 'General',
        'difficulty': difficulty ?? 'Medium',
        'score': score,
        'totalQuestions': totalQuestions,
        'correctAnswers': finalCorrectAnswers,
        'wrongAnswers': finalWrongAnswers,
        'skippedQuestions': skippedQuestions ?? 0,
        'percentage': finalAccuracy,
        'accuracy': finalAccuracy,
        'isPassed': isPassed,
        'timeSpent': timeSpent,
        'completedAt': completedAt,
        'questionAttempts': questionAttempts ?? [],
        'performanceMetrics':
            performanceMetrics ??
            _calculatePerformanceMetrics(
              score: score,
              totalQuestions: totalQuestions,
              timeSpent: timeSpent,
              percentage: finalAccuracy,
            ),
        'timestamp': FieldValue.serverTimestamp(),
        'attemptNumber': await _getUserAttemptNumber(userId, quizId),
      };

      print(
        'Quiz attempt data prepared, saving to quiz_attempts collection...',
      );

      // Save to quiz_attempts collection
      final attemptsRef = _firestore.collection('quiz_attempts');
      await attemptsRef.add(quizAttemptData);
      print('Quiz attempt saved to quiz_attempts collection successfully');

      // Update user document with quiz result
      print('Updating user quiz history...');
      await _updateUserQuizHistory(userId, quizAttemptData);
      print('User quiz history updated successfully');

      // Update user statistics
      print('Updating user quiz statistics...');
      await _updateUserQuizStatistics(userId, quizAttemptData);
      print('User quiz statistics updated successfully');

      // Update quiz statistics
      print('Updating quiz statistics...');
      await _updateQuizStatistics(quizId, quizAttemptData);
      print('Quiz statistics updated successfully');

      print('Comprehensive quiz attempt saved successfully for user: $userId');
    } catch (e) {
      print('Error saving quiz attempt: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to save quiz attempt: $e');
    }
  }

  // Calculate performance metrics
  static Map<String, dynamic> _calculatePerformanceMetrics({
    required int score,
    required int totalQuestions,
    required int timeSpent,
    required double percentage,
  }) {
    final timePerQuestion = totalQuestions > 0 ? timeSpent / totalQuestions : 0;
    final efficiency = timeSpent > 0
        ? (score / timeSpent) * 60
        : 0; // points per minute

    return {
      'timePerQuestion': timePerQuestion,
      'efficiency': efficiency,
      'speed': timeSpent > 0
          ? (totalQuestions / timeSpent) * 60
          : 0, // questions per minute
      'completionRate': 100.0, // assuming all questions were attempted
      'difficultyLevel': _calculateDifficultyLevel(percentage),
      'timeEfficiency': _calculateTimeEfficiency(timeSpent, totalQuestions),
    };
  }

  // Calculate difficulty level based on performance
  static String _calculateDifficultyLevel(double percentage) {
    if (percentage >= 90) return 'Expert';
    if (percentage >= 80) return 'Advanced';
    if (percentage >= 70) return 'Intermediate';
    if (percentage >= 60) return 'Beginner';
    return 'Novice';
  }

  // Calculate time efficiency
  static String _calculateTimeEfficiency(int timeSpent, int totalQuestions) {
    final avgTimePerQuestion = timeSpent / totalQuestions;
    if (avgTimePerQuestion <= 30) return 'Very Fast';
    if (avgTimePerQuestion <= 60) return 'Fast';
    if (avgTimePerQuestion <= 90) return 'Normal';
    if (avgTimePerQuestion <= 120) return 'Slow';
    return 'Very Slow';
  }

  // Get user's attempt number for a specific quiz
  static Future<int> _getUserAttemptNumber(String userId, String quizId) async {
    try {
      final attemptsRef = _firestore.collection('quiz_attempts');
      final querySnapshot = await attemptsRef
          .where('userId', isEqualTo: userId)
          .where('quizId', isEqualTo: quizId)
          .get();

      return querySnapshot.docs.length + 1;
    } catch (e) {
      print('Error getting attempt number: $e');
      return 1;
    }
  }

  // Update user quiz history
  static Future<void> _updateUserQuizHistory(
    String userId,
    Map<String, dynamic> quizResult,
  ) async {
    try {
      // Use set with merge to ensure the document exists
      await _firestore.collection('users').doc(userId).set({
        'quizHistory': FieldValue.arrayUnion([quizResult]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('Updated user quiz history for: $userId');
    } catch (e) {
      print('Error updating user quiz history: $e');
      // Don't throw here as the main quiz attempt was already saved
    }
  }

  // Get user quiz history
  static Future<List<Map<String, dynamic>>> getUserQuizHistory(
    String userId,
  ) async {
    try {
      final attemptsRef = _firestore.collection('quiz_attempts');
      final querySnapshot = await attemptsRef
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'quizId': data['quizId'] ?? '',
          'quizTitle': data['quizTitle'] ?? '',
          'score': data['score'] ?? 0,
          'totalQuestions': data['totalQuestions'] ?? 0,
          'percentage': data['percentage'] ?? 0.0,
          'completedAt': (data['completedAt'] as Timestamp).toDate(),
          'isPassed': data['isPassed'] ?? false,
          'timeSpent': data['timeSpent'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error getting user quiz history: $e');
      return [];
    }
  }

  // Get user quiz stats
  static Future<Map<String, dynamic>> getUserQuizStats(String userId) async {
    try {
      final attemptsRef = _firestore.collection('quiz_attempts');
      final querySnapshot = await attemptsRef
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'totalAttempts': 0,
          'averageScore': 0.0,
          'passedQuizzes': 0,
          'totalTimeSpent': 0,
        };
      }

      final attempts = querySnapshot.docs.map((doc) => doc.data()).toList();

      int totalAttempts = attempts.length;
      double totalScore = attempts.fold(
        0.0,
        (sum, attempt) => sum + (attempt['percentage'] ?? 0.0),
      );
      double averageScore = totalScore / totalAttempts;
      int passedQuizzes = attempts
          .where((attempt) => attempt['isPassed'] == true)
          .length;
      int totalTimeSpent = attempts.fold(
        0,
        (sum, attempt) => sum + (attempt['timeSpent'] as int? ?? 0),
      );

      return {
        'totalAttempts': totalAttempts,
        'averageScore': averageScore,
        'passedQuizzes': passedQuizzes,
        'totalTimeSpent': totalTimeSpent,
      };
    } catch (e) {
      print('Error getting user quiz stats: $e');
      return {
        'totalAttempts': 0,
        'averageScore': 0.0,
        'passedQuizzes': 0,
        'totalTimeSpent': 0,
      };
    }
  }

  // Update user quiz statistics
  static Future<void> _updateUserQuizStatistics(
    String userId,
    Map<String, dynamic> quizData,
  ) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      // Get current user stats
      final userDoc = await userRef.get();
      final currentData = userDoc.data() ?? {};

      // Calculate new statistics
      final currentStats =
          currentData['quizStatistics'] ??
          {
            'totalQuizzes': 0,
            'totalScore': 0,
            'totalQuestions': 0,
            'averageScore': 0.0,
            'passedQuizzes': 0,
            'totalTimeSpent': 0,
            'bestScore': 0,
            'worstScore': 100,
            'totalCorrectAnswers': 0,
            'totalWrongAnswers': 0,
            'averageTimePerQuestion': 0.0,
            'quizCategories': {},
            'difficultyLevels': {},
            'lastQuizDate': null,
            'streakDays': 0,
          };

      final newStats = _calculateUpdatedUserStats(currentStats, quizData);

      // Update user document with new statistics
      await userRef.set({
        'quizStatistics': newStats,
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalScore': FieldValue.increment(quizData['score']),
        'totalQuestions': FieldValue.increment(quizData['totalQuestions']),
        'passedQuizzes': FieldValue.increment(quizData['isPassed'] ? 1 : 0),
        'totalTimeSpent': FieldValue.increment(quizData['timeSpent']),
      }, SetOptions(merge: true));

      print('Updated user quiz statistics for: $userId');
    } catch (e) {
      print('Error updating user quiz statistics: $e');
    }
  }

  // Calculate updated user statistics
  static Map<String, dynamic> _calculateUpdatedUserStats(
    Map<String, dynamic> currentStats,
    Map<String, dynamic> quizData,
  ) {
    final totalQuizzes = (currentStats['totalQuizzes'] ?? 0) + 1;
    final totalScore = (currentStats['totalScore'] ?? 0) + quizData['score'];
    final totalQuestions =
        (currentStats['totalQuestions'] ?? 0) + quizData['totalQuestions'];
    final averageScore = totalQuestions > 0
        ? (totalScore / totalQuestions) * 100
        : 0.0;
    final passedQuizzes =
        (currentStats['passedQuizzes'] ?? 0) + (quizData['isPassed'] ? 1 : 0);
    final totalTimeSpent =
        (currentStats['totalTimeSpent'] ?? 0) + quizData['timeSpent'];
    final totalCorrectAnswers =
        (currentStats['totalCorrectAnswers'] ?? 0) + quizData['correctAnswers'];
    final totalWrongAnswers =
        (currentStats['totalWrongAnswers'] ?? 0) + quizData['wrongAnswers'];

    // Update best and worst scores
    final currentBestScore = currentStats['bestScore'] ?? 0;
    final currentWorstScore = currentStats['worstScore'] ?? 100;
    final bestScore = quizData['score'] > currentBestScore
        ? quizData['score']
        : currentBestScore;
    final worstScore = quizData['score'] < currentWorstScore
        ? quizData['score']
        : currentWorstScore;

    // Calculate average time per question
    final averageTimePerQuestion = totalQuestions > 0
        ? totalTimeSpent / totalQuestions
        : 0.0;

    // Update category statistics
    final quizCategories = Map<String, dynamic>.from(
      currentStats['quizCategories'] ?? {},
    );
    final category = quizData['quizCategory'] ?? 'General';
    if (!quizCategories.containsKey(category)) {
      quizCategories[category] = {
        'attempts': 0,
        'totalScore': 0,
        'averageScore': 0.0,
        'passedCount': 0,
      };
    }
    quizCategories[category]['attempts'] =
        (quizCategories[category]['attempts'] ?? 0) + 1;
    quizCategories[category]['totalScore'] =
        (quizCategories[category]['totalScore'] ?? 0) + quizData['score'];
    quizCategories[category]['averageScore'] =
        quizCategories[category]['totalScore'] /
        quizCategories[category]['attempts'];
    quizCategories[category]['passedCount'] =
        (quizCategories[category]['passedCount'] ?? 0) +
        (quizData['isPassed'] ? 1 : 0);

    // Update difficulty level statistics
    final difficultyLevels = Map<String, dynamic>.from(
      currentStats['difficultyLevels'] ?? {},
    );
    final difficulty = quizData['difficulty'] ?? 'Medium';
    if (!difficultyLevels.containsKey(difficulty)) {
      difficultyLevels[difficulty] = {
        'attempts': 0,
        'totalScore': 0,
        'averageScore': 0.0,
        'passedCount': 0,
      };
    }
    difficultyLevels[difficulty]['attempts'] =
        (difficultyLevels[difficulty]['attempts'] ?? 0) + 1;
    difficultyLevels[difficulty]['totalScore'] =
        (difficultyLevels[difficulty]['totalScore'] ?? 0) + quizData['score'];
    difficultyLevels[difficulty]['averageScore'] =
        difficultyLevels[difficulty]['totalScore'] /
        difficultyLevels[difficulty]['attempts'];
    difficultyLevels[difficulty]['passedCount'] =
        (difficultyLevels[difficulty]['passedCount'] ?? 0) +
        (quizData['isPassed'] ? 1 : 0);

    return {
      'totalQuizzes': totalQuizzes,
      'totalScore': totalScore,
      'totalQuestions': totalQuestions,
      'averageScore': averageScore,
      'passedQuizzes': passedQuizzes,
      'totalTimeSpent': totalTimeSpent,
      'bestScore': bestScore,
      'worstScore': worstScore,
      'totalCorrectAnswers': totalCorrectAnswers,
      'totalWrongAnswers': totalWrongAnswers,
      'averageTimePerQuestion': averageTimePerQuestion,
      'quizCategories': quizCategories,
      'difficultyLevels': difficultyLevels,
      'lastQuizDate': quizData['completedAt'],
      'streakDays': _calculateStreakDays(
        currentStats['lastQuizDate'],
        quizData['completedAt'],
        currentStats['streakDays'],
      ),
    };
  }

  // Calculate streak days
  static int _calculateStreakDays(
    DateTime? lastQuizDate,
    DateTime currentQuizDate,
    int currentStreak,
  ) {
    if (lastQuizDate == null) return 1;

    final difference = currentQuizDate.difference(lastQuizDate).inDays;
    if (difference == 1) {
      return currentStreak + 1;
    } else if (difference == 0) {
      return currentStreak; // Same day, maintain streak
    } else {
      return 1; // Reset streak
    }
  }

  // Update quiz statistics
  static Future<void> _updateQuizStatistics(
    String quizId,
    Map<String, dynamic> quizData,
  ) async {
    try {
      final quizRef = _firestore.collection('quizzes').doc(quizId);

      // Check if quiz document exists
      final quizDoc = await quizRef.get();
      if (!quizDoc.exists) {
        // Create quiz statistics document if it doesn't exist
        await quizRef.set({
          'quizId': quizId,
          'quizTitle': quizData['quizTitle'],
          'quizCategory': quizData['quizCategory'],
          'difficulty': quizData['difficulty'],
          'statistics': {
            'totalAttempts': 0,
            'totalParticipants': 0,
            'averageScore': 0.0,
            'averageTime': 0.0,
            'passRate': 0.0,
            'bestScore': 0,
            'worstScore': 100,
            'scoreDistribution': {},
            'timeDistribution': {},
            'lastAttemptDate': null,
            'createdAt': FieldValue.serverTimestamp(),
          },
        });
      }

      // Update quiz statistics
      final currentStats = quizDoc.data()?['statistics'] ?? {};
      final newStats = _calculateUpdatedQuizStats(currentStats, quizData);

      // Use set with merge to ensure the document exists and update safely
      await quizRef.set({
        'statistics': newStats,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Updated quiz statistics for: $quizId');
    } catch (e) {
      print('Error updating quiz statistics: $e');
      // Don't throw here as the main quiz attempt was already saved
    }
  }

  // Calculate updated quiz statistics
  static Map<String, dynamic> _calculateUpdatedQuizStats(
    Map<String, dynamic> currentStats,
    Map<String, dynamic> quizData,
  ) {
    try {
      final totalAttempts = (currentStats['totalAttempts'] ?? 0) + 1;
      final totalParticipants = (currentStats['totalParticipants'] ?? 0) + 1;

      // Safely get quiz data with defaults
      final quizPercentage = (quizData['percentage'] ?? 0.0).toDouble();
      final quizTimeSpent = (quizData['timeSpent'] ?? 0).toInt();
      final quizScore = (quizData['score'] ?? 0).toInt();
      final quizIsPassed = quizData['isPassed'] ?? false;

      // Calculate new average score
      final currentTotalScore =
          (currentStats['averageScore'] ?? 0.0) * (totalAttempts - 1);
      final newTotalScore = currentTotalScore + quizPercentage;
      final averageScore = totalAttempts > 0
          ? newTotalScore / totalAttempts
          : 0.0;

      // Calculate new average time
      final currentTotalTime =
          (currentStats['averageTime'] ?? 0.0) * (totalAttempts - 1);
      final newTotalTime = currentTotalTime + quizTimeSpent;
      final averageTime = totalAttempts > 0
          ? newTotalTime / totalAttempts
          : 0.0;

      // Calculate pass rate
      final currentPassedCount =
          (currentStats['passRate'] ?? 0.0) * (totalAttempts - 1) / 100;
      final newPassedCount = currentPassedCount + (quizIsPassed ? 1 : 0);
      final passRate = totalAttempts > 0
          ? (newPassedCount / totalAttempts) * 100
          : 0.0;

      // Update best and worst scores
      final currentBestScore = currentStats['bestScore'] ?? 0;
      final currentWorstScore = currentStats['worstScore'] ?? 100;
      final bestScore = quizScore > currentBestScore
          ? quizScore
          : currentBestScore;
      final worstScore = quizScore < currentWorstScore
          ? quizScore
          : currentWorstScore;

      // Update score distribution
      final scoreDistribution = Map<String, dynamic>.from(
        currentStats['scoreDistribution'] ?? {},
      );
      final scoreRange = _getScoreRange(quizPercentage);
      scoreDistribution[scoreRange] = (scoreDistribution[scoreRange] ?? 0) + 1;

      // Update time distribution
      final timeDistribution = Map<String, dynamic>.from(
        currentStats['timeDistribution'] ?? {},
      );
      final timeRange = _getTimeRange(quizTimeSpent);
      timeDistribution[timeRange] = (timeDistribution[timeRange] ?? 0) + 1;

      return {
        'totalAttempts': totalAttempts,
        'totalParticipants': totalParticipants,
        'averageScore': averageScore,
        'averageTime': averageTime,
        'passRate': passRate,
        'bestScore': bestScore,
        'worstScore': worstScore,
        'scoreDistribution': scoreDistribution,
        'timeDistribution': timeDistribution,
        'lastAttemptDate': quizData['completedAt'],
      };
    } catch (e) {
      print('Error calculating updated quiz stats: $e');
      // Return default stats if calculation fails
      return {
        'totalAttempts': 1,
        'totalParticipants': 1,
        'averageScore': quizData['percentage'] ?? 0.0,
        'averageTime': quizData['timeSpent'] ?? 0.0,
        'passRate': (quizData['isPassed'] ?? false) ? 100.0 : 0.0,
        'bestScore': quizData['score'] ?? 0,
        'worstScore': quizData['score'] ?? 0,
        'scoreDistribution': {},
        'timeDistribution': {},
        'lastAttemptDate': quizData['completedAt'],
      };
    }
  }

  // Get score range for distribution
  static String _getScoreRange(dynamic percentage) {
    try {
      final score = (percentage ?? 0.0).toDouble();
      if (score >= 90) return '90-100';
      if (score >= 80) return '80-89';
      if (score >= 70) return '70-79';
      if (score >= 60) return '60-69';
      if (score >= 50) return '50-59';
      return '0-49';
    } catch (e) {
      print('Error getting score range: $e');
      return '0-49';
    }
  }

  // Get time range for distribution
  static String _getTimeRange(dynamic timeSpent) {
    try {
      final time = (timeSpent ?? 0).toInt();
      if (time <= 30) return '0-30s';
      if (time <= 60) return '31-60s';
      if (time <= 120) return '1-2m';
      if (time <= 300) return '2-5m';
      if (time <= 600) return '5-10m';
      return '10m+';
    } catch (e) {
      print('Error getting time range: $e');
      return '0-30s';
    }
  }

  // Ensure user document exists
  static Future<void> _ensureUserDocumentExists(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        // Try to get user info from Firebase Auth first
        final firebaseUser = _auth.currentUser;
        String userName = 'User';
        String userEmail = '';

        if (firebaseUser != null) {
          // If we have a Firebase user, try to get their display name
          if (firebaseUser.displayName != null &&
              firebaseUser.displayName!.isNotEmpty) {
            userName = firebaseUser.displayName!;
          }
          userEmail = firebaseUser.email ?? '';
        }

        // Create a basic user document if it doesn't exist
        final userData = {
          'id': userId,
          'name': userName,
          'email': userEmail,
          'avatarUrl': firebaseUser?.photoURL,
          'quizHistory': [],
          'tasksCount': 0,
          'quizStatistics': {
            'totalQuizzes': 0,
            'totalScore': 0,
            'totalQuestions': 0,
            'averageScore': 0.0,
            'passedQuizzes': 0,
            'totalTimeSpent': 0,
            'bestScore': 0,
            'worstScore': 100,
            'totalCorrectAnswers': 0,
            'totalWrongAnswers': 0,
            'averageTimePerQuestion': 0.0,
            'quizCategories': {},
            'difficultyLevels': {},
            'lastQuizDate': null,
            'streakDays': 0,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(userId).set(userData);
        print(
          'Created missing user document for: $userId with name: $userName',
        );
      } else {
        // Check if the document has the correct name and email
        final data = userDoc.data()!;
        final currentName = data['name'] ?? 'User';
        final currentEmail = data['email'] ?? '';

        // Get current user info from Firebase Auth
        final firebaseUser = _auth.currentUser;
        String actualName = currentName;
        String actualEmail = currentEmail;

        if (firebaseUser != null) {
          // If Firebase Auth has a display name, use it
          if (firebaseUser.displayName != null &&
              firebaseUser.displayName!.isNotEmpty) {
            actualName = firebaseUser.displayName!;
          }
          // Always use the email from Firebase Auth
          actualEmail = firebaseUser.email ?? '';
        }

        // Update name and email if they don't match
        if (currentName != actualName || currentEmail != actualEmail) {
          await _firestore.collection('users').doc(userId).update({
            'name': actualName,
            'email': actualEmail,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          print(
            'Updated user document with correct name: $actualName and email: $actualEmail',
          );
        }

        // Ensure the document has all required fields
        final hasQuizStatistics = data.containsKey('quizStatistics');
        final hasQuizHistory = data.containsKey('quizHistory');

        if (!hasQuizStatistics || !hasQuizHistory) {
          final updates = <String, dynamic>{};

          if (!hasQuizStatistics) {
            updates['quizStatistics'] = {
              'totalQuizzes': 0,
              'totalScore': 0,
              'totalQuestions': 0,
              'averageScore': 0.0,
              'passedQuizzes': 0,
              'totalTimeSpent': 0,
              'bestScore': 0,
              'worstScore': 100,
              'totalCorrectAnswers': 0,
              'totalWrongAnswers': 0,
              'averageTimePerQuestion': 0.0,
              'quizCategories': {},
              'difficultyLevels': {},
              'lastQuizDate': null,
              'streakDays': 0,
            };
          }

          if (!hasQuizHistory) {
            updates['quizHistory'] = [];
          }

          if (updates.isNotEmpty) {
            updates['lastUpdated'] = FieldValue.serverTimestamp();
            await _firestore.collection('users').doc(userId).update(updates);
            print(
              'Updated existing user document with missing fields for: $userId',
            );
          }
        }
      }
    } catch (e) {
      print('Error ensuring user document exists: $e');
      // Try to create a minimal document as last resort
      try {
        final firebaseUser = _auth.currentUser;
        String userName = 'User';
        String userEmail = '';

        if (firebaseUser != null) {
          if (firebaseUser.displayName != null &&
              firebaseUser.displayName!.isNotEmpty) {
            userName = firebaseUser.displayName!;
          }
          userEmail = firebaseUser.email ?? '';
        }

        await _firestore.collection('users').doc(userId).set({
          'id': userId,
          'name': userName,
          'email': userEmail,
          'avatarUrl': firebaseUser?.photoURL,
          'quizHistory': [],
          'tasksCount': 0,
          'quizStatistics': {
            'totalQuizzes': 0,
            'totalScore': 0,
            'totalQuestions': 0,
            'averageScore': 0.0,
            'passedQuizzes': 0,
            'totalTimeSpent': 0,
            'bestScore': 0,
            'worstScore': 100,
            'totalCorrectAnswers': 0,
            'totalWrongAnswers': 0,
            'averageTimePerQuestion': 0.0,
            'quizCategories': {},
            'difficultyLevels': {},
            'lastQuizDate': null,
            'streakDays': 0,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print(
          'Created minimal user document as fallback for: $userId with name: $userName',
        );
      } catch (fallbackError) {
        print('Failed to create fallback user document: $fallbackError');
        throw Exception(
          'Failed to ensure user document exists: $fallbackError',
        );
      }
    }
  }
}
