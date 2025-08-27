// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/quiz.dart';
import '../models/task.dart';
import '../models/chat.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  List<Quiz> _availableQuizzes = [];
  List<Task> _userTasks = [];
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  bool _isFirebaseAvailable = false;

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Getters
  User? get currentUser => _currentUser;
  List<Quiz> get availableQuizzes => _availableQuizzes;
  List<Task> get userTasks => _userTasks;
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  // Initialize with Firebase integration
  Future<void> initializeApp() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load current user profile if authenticated
      await _loadCurrentUserProfile();

      // Try to load quizzes from Firebase first
      final firebaseQuizzes = await FirebaseService.getAvailableQuizzes();
      if (firebaseQuizzes.isNotEmpty) {
        _availableQuizzes = firebaseQuizzes;
        _isFirebaseAvailable = true;
        print('Loaded ${firebaseQuizzes.length} quizzes from Firebase');
      } else {
        // Fallback to mock data if Firebase is empty
        _loadMockData();
        print('No quizzes in Firebase, using mock data');
      }
    } catch (e) {
      print('Firebase not available, using mock data: $e');
      _loadMockData();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Initialize app when user signs in
  Future<void> initializeUserApp() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load current user profile
      await _loadCurrentUserProfile();

      // Load user-specific data
      await _loadUserData();

      // Try to load quizzes from Firebase
      final firebaseQuizzes = await FirebaseService.getAvailableQuizzes();
      if (firebaseQuizzes.isNotEmpty) {
        _availableQuizzes = firebaseQuizzes;
        _isFirebaseAvailable = true;
        print('Loaded ${firebaseQuizzes.length} quizzes from Firebase');
      }
    } catch (e) {
      print('Failed to initialize user app: $e');
      // Load mock data as fallback
      _loadMockData();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load current user profile
  Future<void> _loadCurrentUserProfile() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        print('Loading user profile for: ${firebaseUser.uid}');
        print('Firebase Auth display name: ${firebaseUser.displayName}');

        // First, try to get the user profile from Firestore
        final userProfile = await AuthService.getUserProfile(firebaseUser.uid);

        if (userProfile != null) {
          _currentUser = userProfile;
          print('Loaded user profile from Firestore: ${userProfile.name}');

          // Ensure Firebase Auth display name is synchronized
          if (firebaseUser.displayName != userProfile.name &&
              userProfile.name.isNotEmpty) {
            try {
              await firebaseUser.updateDisplayName(userProfile.name);
              print(
                'Updated Firebase Auth display name to: ${userProfile.name}',
              );
            } catch (e) {
              print('Warning: Could not update Firebase Auth display name: $e');
            }
          }
        } else {
          // User profile should have been created by AuthService during sign-in/registration
          // If we still don't have one, create a minimal profile
          print('User profile not found, creating minimal profile');
          await _createMinimalUserProfile(firebaseUser);
        }
      }
    } catch (e) {
      print('Error loading current user profile: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Create minimal user profile (fallback)
  Future<void> _createMinimalUserProfile(
    firebase_auth.User firebaseUser,
  ) async {
    try {
      print('Creating minimal user profile for: ${firebaseUser.uid}');

      // Wait a bit to ensure Firebase Auth is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      // Double-check if profile was created in the meantime
      final existingProfile = await AuthService.getUserProfile(
        firebaseUser.uid,
      );
      if (existingProfile != null) {
        _currentUser = existingProfile;
        print(
          'Profile was created by another process: ${existingProfile.name}',
        );
        return;
      }

      // Generate a fallback name from email
      final fallbackName = _generateFallbackName(firebaseUser.email ?? 'User');

      final minimalUser = User(
        id: firebaseUser.uid,
        name: fallbackName,
        email: firebaseUser.email ?? '',
        avatarUrl: firebaseUser.photoURL,
        quizHistory: [],
        tasksCount: 0,
      );

      // Use set with merge to avoid conflicts
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(minimalUser.toJson(), SetOptions(merge: true));

      _currentUser = minimalUser;
      print('Created minimal user profile: ${minimalUser.name}');

      // Also update Firebase Auth display name
      if (firebaseUser.displayName != fallbackName) {
        try {
          await firebaseUser.updateDisplayName(fallbackName);
          print('Updated Firebase Auth display name to: $fallbackName');
        } catch (e) {
          print('Warning: Could not update Firebase Auth display name: $e');
        }
      }
    } catch (e) {
      print('Error creating minimal user profile: $e');
      print('Stack trace: ${StackTrace.current}');

      // Try one more time with a longer delay
      try {
        await Future.delayed(const Duration(seconds: 1));

        final existingProfile = await AuthService.getUserProfile(
          firebaseUser.uid,
        );
        if (existingProfile != null) {
          _currentUser = existingProfile;
          print('Profile found on retry: ${existingProfile.name}');
          return;
        }

        print('Failed to create profile even after retry');
      } catch (retryError) {
        print('Retry also failed: $retryError');
      }
    }
  }

  // Generate fallback name from email
  String _generateFallbackName(String email) {
    if (email.isEmpty || email == 'User') return 'User';

    // Extract username part from email (before @)
    final username = email.split('@').first;
    if (username.isNotEmpty) {
      // Capitalize first letter and return
      return username[0].toUpperCase() + username.substring(1);
    }

    return 'User';
  }

  // Load user-specific data
  Future<void> _loadUserData() async {
    try {
      if (_currentUser != null) {
        // Load user tasks, conversations, etc. from Firebase
        // For now, we'll use mock data, but this can be expanded
        _loadMockData();
      }
    } catch (e) {
      print('Failed to load user data: $e');
    }
  }

  // Refresh quizzes from Firebase
  Future<void> refreshQuizzes() async {
    if (!_isFirebaseAvailable) return;

    try {
      _isLoading = true;
      notifyListeners();

      final firebaseQuizzes = await FirebaseService.getAvailableQuizzes();
      if (firebaseQuizzes.isNotEmpty) {
        _availableQuizzes = firebaseQuizzes;
        print('Refreshed ${firebaseQuizzes.length} quizzes from Firebase');
      }
    } catch (e) {
      print('Failed to refresh quizzes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh user profile from Firebase
  Future<void> refreshUserProfile() async {
    try {
      await _loadCurrentUserProfile();
      notifyListeners();
    } catch (e) {
      print('Failed to refresh user profile: $e');
    }
  }

  void _loadMockData() {
    _isLoading = true;
    notifyListeners();

    // Mock user data
    _currentUser = User(
      id: '1',
      name: 'John Doe',
      email: 'john.doe@example.com',
      quizHistory: [
        QuizResult(
          quizId: '1',
          quizTitle: 'Flutter Basics',
          score: 8,
          totalQuestions: 10,
          completedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        QuizResult(
          quizId: '2',
          quizTitle: 'Dart Fundamentals',
          score: 7,
          totalQuestions: 10,
          completedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
      tasksCount: 5,
    );

    // Mock quizzes
    _availableQuizzes = [
      Quiz(
        id: '1',
        title: 'Flutter Basics',
        description: 'Test your knowledge of Flutter fundamentals',
        questions: [
          Question(
            id: '1',
            questionText: 'What is Flutter?',
            options: [
              'A programming language',
              'A UI framework',
              'A database',
              'An operating system',
            ],
            correctAnswerIndex: 1,
            explanation:
                'Flutter is Google\'s UI toolkit for building natively compiled applications.',
          ),
          Question(
            id: '2',
            questionText: 'Which programming language does Flutter use?',
            options: ['Java', 'Kotlin', 'Dart', 'Swift'],
            correctAnswerIndex: 2,
            explanation: 'Flutter uses Dart programming language.',
          ),
        ],
        timeLimit: 15,
        category: 'Programming',
      ),
      Quiz(
        id: '2',
        title: 'Dart Fundamentals',
        description: 'Learn the basics of Dart programming',
        questions: [
          Question(
            id: '3',
            questionText: 'What is the main function in Dart?',
            options: ['start()', 'main()', 'begin()', 'init()'],
            correctAnswerIndex: 1,
            explanation:
                'The main() function is the entry point of a Dart program.',
          ),
        ],
        timeLimit: 10,
        category: 'Programming',
      ),
    ];

    // Mock tasks
    _userTasks = [
      Task(
        id: '1',
        title: 'Complete Flutter Quiz',
        description: 'Take the Flutter Basics quiz and score at least 80%',
        status: TaskStatus.completed,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        priority: 4,
      ),
      Task(
        id: '2',
        title: 'Build Navigation App',
        description: 'Create a simple app with bottom navigation',
        status: TaskStatus.inProgress,
        dueDate: DateTime.now().add(const Duration(days: 3)),
        priority: 5,
      ),
      Task(
        id: '3',
        title: 'Review Code',
        description: 'Review and refactor existing code',
        status: TaskStatus.pending,
        dueDate: DateTime.now().add(const Duration(days: 7)),
        priority: 3,
      ),
    ];

    // Mock conversations
    _conversations = [
      Conversation(
        id: '1',
        title: 'Study Group',
        participantIds: ['1', '2', '3'],
        messages: [
          ChatMessage(
            id: '1',
            senderId: '2',
            senderName: 'Alice',
            message: 'Hey everyone! How\'s the Flutter learning going?',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          ChatMessage(
            id: '2',
            senderId: '1',
            senderName: 'John Doe',
            message: 'Great! Just completed the Flutter Basics quiz with 80%',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
        isGroupChat: true,
      ),
      Conversation(
        id: '2',
        title: 'Alice Smith',
        participantIds: ['1', '2'],
        messages: [
          ChatMessage(
            id: '3',
            senderId: '2',
            senderName: 'Alice',
            message: 'Can you help me with the navigation task?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
        isGroupChat: false,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  // Quiz methods
  Future<void> addQuizResult(QuizResult result) async {
    try {
      print('Adding quiz result to app state: ${result.quizTitle}');

      if (_currentUser != null) {
        // Update local state first
        _currentUser = _currentUser!.copyWith(
          quizHistory: [..._currentUser!.quizHistory, result],
        );
        notifyListeners();
        print('Local state updated successfully');

        // Save to Firebase
        await _saveQuizResultToFirebase(result);
        print('Quiz result saved to Firebase successfully');
      } else {
        print('Warning: No current user, skipping quiz result save');
        // Still try to save to Firebase directly
        try {
          final userId = AuthService.currentUserId;
          if (userId != null) {
            await _firestore.collection('users').doc(userId).set({
              'quizHistory': FieldValue.arrayUnion([result.toJson()]),
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            print('Quiz result saved to Firebase directly');
          }
        } catch (e) {
          print('Failed to save quiz result directly to Firebase: $e');
        }
      }
    } catch (e) {
      print('Error in addQuizResult: $e');

      // Revert local state if there was an error
      if (_currentUser != null && _currentUser!.quizHistory.isNotEmpty) {
        try {
          _currentUser = _currentUser!.copyWith(
            quizHistory: _currentUser!.quizHistory.sublist(
              0,
              _currentUser!.quizHistory.length - 1,
            ),
          );
          notifyListeners();
          print('Local state reverted due to error');
        } catch (revertError) {
          print('Failed to revert local state: $revertError');
        }
      }

      throw Exception('Failed to save quiz result: $e');
    }
  }

  // Save quiz result to Firebase
  Future<void> _saveQuizResultToFirebase(QuizResult result) async {
    try {
      if (_currentUser != null) {
        // Use set with merge to ensure the document exists and update safely
        await _firestore.collection('users').doc(_currentUser!.id).set({
          'quizHistory': _currentUser!.quizHistory
              .map((r) => r.toJson())
              .toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('Quiz result saved to Firebase successfully');
      }
    } catch (e) {
      print('Error saving quiz result to Firebase: $e');
      rethrow;
    }
  }

  // Task methods - Now handled by TaskProvider
  // These methods are kept for backward compatibility but delegate to TaskProvider
  void addTask(Task task) {
    // Task management is now handled by TaskProvider
    // This method is kept for backward compatibility
    print(
      'Task management moved to TaskProvider - use context.read<TaskProvider>().addTask() instead',
    );
  }

  void updateTaskStatus(String taskId, TaskStatus status) {
    // Task management is now handled by TaskProvider
    // This method is kept for backward compatibility
    print(
      'Task management moved to TaskProvider - use context.read<TaskProvider>().updateTaskStatus() instead',
    );
  }

  void deleteTask(String taskId) {
    // Task management is now handled by TaskProvider
    // This method is kept for backward compatibility
    print(
      'Task management moved to TaskProvider - use context.read<TaskProvider>().deleteTask() instead',
    );
  }

  // Chat methods
  void addMessage(String conversationId, ChatMessage message) {
    final conversationIndex = _conversations.indexWhere(
      (conv) => conv.id == conversationId,
    );
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = Conversation(
        id: _conversations[conversationIndex].id,
        title: _conversations[conversationIndex].title,
        participantIds: _conversations[conversationIndex].participantIds,
        messages: [..._conversations[conversationIndex].messages, message],
        lastActivity: DateTime.now(),
        isGroupChat: _conversations[conversationIndex].isGroupChat,
      );
      notifyListeners();
    }
  }

  // User methods
  Future<void> updateUserProfile(String name, String email) async {
    if (_currentUser != null) {
      try {
        // Update in Firebase
        await AuthService.updateUserProfile(
          userId: _currentUser!.id,
          name: name,
          email: email,
        );

        // Update local state
        _currentUser = _currentUser!.copyWith(name: name, email: email);
        notifyListeners();
        print('Profile updated successfully');
      } catch (e) {
        print('Failed to update profile: $e');
        throw Exception('Failed to update profile: $e');
      }
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await AuthService.signOut();
      _currentUser = null;
      _availableQuizzes = [];
      _userTasks = [];
      _conversations = [];
      notifyListeners();
    } catch (e) {
      print('Failed to sign out: $e');
    }
  }
}
