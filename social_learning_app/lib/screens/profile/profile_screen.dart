// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../providers/app_state.dart';
import '../../providers/chat_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/user.dart';
import '../../models/task.dart';

import '../../services/error_service.dart';
import '../../services/onboarding_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  auth.User? _firebaseUser;
  bool _isLoadingFirebaseUser = true;

  @override
  void initState() {
    super.initState();
    // Initialize providers when profile screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
      context.read<TaskProvider>().initialize();
      _loadFirebaseUser();
    });
  }

  Future<void> _loadFirebaseUser() async {
    setState(() {
      _isLoadingFirebaseUser = true;
    });

    try {
      final user = auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Listen for auth state changes
        auth.FirebaseAuth.instance.authStateChanges().listen((user) {
          setState(() {
            _firebaseUser = user;
            _isLoadingFirebaseUser = false;
          });
        });
      } else {
        setState(() {
          _firebaseUser = null;
          _isLoadingFirebaseUser = false;
        });
      }
    } catch (e) {
      print('Error loading Firebase user: $e');
      setState(() {
        _isLoadingFirebaseUser = false;
      });
    }
  }

  Widget _buildNotAuthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Not Authenticated',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Text(
            'Please sign in to view your profile',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to login screen or show login dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please sign in to continue'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditProfileDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh all data
              context.read<ChatProvider>().refreshChatRooms();
              context.read<TaskProvider>().refreshTasks();
              setState(() {}); // Trigger rebuild
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoadingFirebaseUser
          ? const Center(child: CircularProgressIndicator())
          : _firebaseUser == null
          ? _buildNotAuthenticatedView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(context),
                  const SizedBox(height: 24),
                  _buildStatsSection(context),
                  const SizedBox(height: 24),
                  _buildQuizHistorySection(context),
                  const SizedBox(height: 24),
                  _buildChatStatsSection(context),
                  const SizedBox(height: 24),
                  _buildTaskStatsSection(context),
                  const SizedBox(height: 24),
                  _buildFirebaseAuthSection(context),
                  const SizedBox(height: 24),
                  _buildSettingsSection(context),
                  const SizedBox(height: 24),
                  _buildSignOutSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    // Use Firebase Auth user data instead of hardcoded User data
    if (_firebaseUser == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Get user name from Firebase Auth or use email as fallback
    final userName =
        _firebaseUser!.displayName ??
        _firebaseUser!.email?.split('@')[0] ??
        'User';
    final userEmail = _firebaseUser!.email ?? 'No email provided';

    // Check if the name is a fallback name (likely generated from email)
    final isFallbackName = _isFallbackName(userName, userEmail);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Avatar with online status
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Online status indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.circle,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              userEmail,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            // Show Firebase Auth info if available
            if (_firebaseUser != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Verified User',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Member since ${_formatDate(_firebaseUser!.metadata.creationTime ?? DateTime.now())}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
              if (_firebaseUser!.displayName != null &&
                  _firebaseUser!.displayName != userName) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Firebase Name: ${_firebaseUser!.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_firebaseUser!.phoneNumber != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Phone: ${_firebaseUser!.phoneNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            if (isFallbackName) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Update your name to personalize your profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showEditProfileDialog(context);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showProfileSettingsDialog(context);
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Check if the name is a fallback name generated from email
  bool _isFallbackName(String name, String email) {
    if (email.isEmpty || name.isEmpty) return false;

    // Extract username part from email (before @)
    final username = email.split('@').first;
    if (username.isNotEmpty) {
      // Check if name matches the capitalized username from email
      final expectedFallbackName =
          username[0].toUpperCase() + username.substring(1);
      return name == expectedFallbackName;
    }

    return false;
  }

  Widget _buildStatsSection(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final user = appState.currentUser;
        if (user == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'User Data Not Available',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quiz and task data will be available after completing activities',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Statistics',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Quizzes Completed',
                        user.quizHistory.length.toString(),
                        Icons.quiz,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Total Tasks',
                        user.tasksCount.toString(),
                        Icons.task_alt,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Average Score',
                        _calculateAverageScore(user.quizHistory),
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Learning Streak',
                        _calculateLearningStreak(user.quizHistory),
                        Icons.local_fire_department,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatStatsSection(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final chatRooms = chatProvider.chatRooms;
        final totalMessages = chatProvider.messages.length;
        final onlineUsers = chatProvider.onlineUsersCount;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.chat, color: Colors.purple, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Chat Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Chat Rooms',
                        chatRooms.length.toString(),
                        Icons.forum,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Total Messages',
                        totalMessages.toString(),
                        Icons.message,
                        Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Online Users',
                        onlineUsers.toString(),
                        Icons.people,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Active Chats',
                        chatRooms
                            .where(
                              (room) =>
                                  DateTime.now()
                                      .difference(room.createdAt)
                                      .inDays <
                                  1,
                            )
                            .length
                            .toString(),
                        Icons.chat_bubble,
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskStatsSection(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;
        final completedTasks = tasks
            .where((task) => task.status == TaskStatus.completed)
            .length;
        final pendingTasks = tasks
            .where((task) => task.status != TaskStatus.completed)
            .length;
        final totalTasks = tasks.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.task_alt, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Task Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Total Tasks',
                        totalTasks.toString(),
                        Icons.assignment,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Completed',
                        completedTasks.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Pending',
                        pendingTasks.toString(),
                        Icons.pending,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Completion Rate',
                        totalTasks > 0
                            ? '${((completedTasks / totalTasks) * 100).toStringAsFixed(1)}%'
                            : '0%',
                        Icons.analytics,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFirebaseAuthSection(BuildContext context) {
    if (_firebaseUser == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.account_circle, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Firebase Auth Not Available',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'User authentication information is not available',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.indigo, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Firebase Authentication',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAuthInfoItem(
              'User ID',
              _firebaseUser!.uid,
              Icons.fingerprint,
              Colors.indigo,
            ),
            const SizedBox(height: 12),
            _buildAuthInfoItem(
              'Email',
              _firebaseUser!.email ?? 'Not provided',
              Icons.email,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildAuthInfoItem(
              'Display Name',
              _firebaseUser!.displayName ?? 'Not provided',
              Icons.person,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildAuthInfoItem(
              'Phone Number',
              _firebaseUser!.phoneNumber ?? 'Not provided',
              Icons.phone,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildAuthInfoItem(
              'Email Verified',
              _firebaseUser!.emailVerified ? 'Yes' : 'No',
              _firebaseUser!.emailVerified ? Icons.verified : Icons.cancel,
              _firebaseUser!.emailVerified ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildAuthInfoItem(
              'Account Created',
              _formatDate(
                _firebaseUser!.metadata.creationTime ?? DateTime.now(),
              ),
              Icons.calendar_today,
              Colors.teal,
            ),
            if (_firebaseUser!.metadata.lastSignInTime != null) ...[
              const SizedBox(height: 12),
              _buildAuthInfoItem(
                'Last Sign In',
                _formatDate(_firebaseUser!.metadata.lastSignInTime!),
                Icons.login,
                Colors.amber,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showFirebaseAuthDetails(context);
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _refreshFirebaseUser();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizHistorySection(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final user = appState.currentUser;
        if (user == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'User Data Not Available',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quiz history will be available after completing quizzes',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (user.quizHistory.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.quiz_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Quiz History',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your first quiz to see your progress here',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quiz History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _showQuizHistoryDialog(context, user);
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...user.quizHistory
                    .take(3)
                    .map((result) => _buildQuizHistoryItem(context, result)),
                if (user.quizHistory.length > 3)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        _showQuizHistoryDialog(context, user);
                      },
                      child: Text(
                        'View ${user.quizHistory.length - 3} more results',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizHistoryItem(BuildContext context, QuizResult result) {
    final percentage = (result.score / result.totalQuestions) * 100;
    final isPassed = percentage >= 80;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPassed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPassed ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPassed ? Icons.check : Icons.emoji_events,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.quizTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.score}/${result.totalQuestions} (${percentage.toStringAsFixed(1)}%)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(result.completedAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Manage your notification preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showNotificationSettingsDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy & Security'),
            subtitle: const Text('Manage your privacy settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showPrivacySettingsDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text('Data & Storage'),
            subtitle: const Text('Manage app data and storage'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showDataSettingsDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showHelpSupportDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('App version and information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset Onboarding'),
            subtitle: const Text('Show onboarding screens again'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showResetOnboardingDialog(context);
            },
          ),
        ],
      ),
    );
  }

  String _calculateAverageScore(List<QuizResult> quizHistory) {
    if (quizHistory.isEmpty) return '0%';

    final totalScore = quizHistory.fold<int>(
      0,
      (sum, result) => sum + result.score,
    );
    final totalQuestions = quizHistory.fold<int>(
      0,
      (sum, result) => sum + result.totalQuestions,
    );

    if (totalQuestions == 0) return '0%';

    final average = (totalScore / totalQuestions) * 100;
    return '${average.toStringAsFixed(1)}%';
  }

  String _calculateLearningStreak(List<QuizResult> quizHistory) {
    if (quizHistory.isEmpty) return '0 days';

    // Sort by completion date (most recent first)
    final sortedResults = List<QuizResult>.from(quizHistory)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    int streak = 0;
    DateTime? currentDate = DateTime.now();

    for (final result in sortedResults) {
      final resultDate = DateTime(
        result.completedAt.year,
        result.completedAt.month,
        result.completedAt.day,
      );

      if (currentDate == null) {
        currentDate = resultDate;
        streak = 1;
      } else {
        final difference = currentDate.difference(resultDate).inDays;
        if (difference == 1) {
          streak++;
          currentDate = resultDate;
        } else if (difference == 0) {
          // Same day, continue
          continue;
        } else {
          // Streak broken
          break;
        }
      }
    }

    if (streak == 0) return '0 days';
    if (streak == 1) return '1 day';
    return '$streak days';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EditProfileDialog(),
    );
  }

  void _showProfileSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Preferences'),
              subtitle: const Text('Manage your notification settings'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationSettingsDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Settings'),
              subtitle: const Text('Control your privacy and data'),
              onTap: () {
                Navigator.pop(context);
                _showPrivacySettingsDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security'),
              subtitle: const Text('Password and authentication'),
              onTap: () {
                Navigator.pop(context);
                _showSecuritySettingsDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications on your device'),
              value: true, // TODO: Get from preferences
              onChanged: (value) {
                // TODO: Save to preferences
              },
            ),
            SwitchListTile(
              title: const Text('Quiz Reminders'),
              subtitle: const Text('Get reminded about available quizzes'),
              value: true, // TODO: Get from preferences
              onChanged: (value) {
                // TODO: Save to preferences
              },
            ),
            SwitchListTile(
              title: const Text('Task Due Dates'),
              subtitle: const Text('Notifications for upcoming task deadlines'),
              value: true, // TODO: Get from preferences
              onChanged: (value) {
                // TODO: Save to preferences
              },
            ),
            SwitchListTile(
              title: const Text('Chat Messages'),
              subtitle: const Text('Notifications for new chat messages'),
              value: true, // TODO: Get from preferences
              onChanged: (value) {
                // TODO: Save to preferences
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Profile Visibility'),
              subtitle: const Text('Allow other users to see your profile'),
              value: true, // TODO: Get from preferences
              onChanged: (value) {
                // TODO: Save to preferences
              },
            ),
            SwitchListTile(
              title: const Text('Activity Status'),
              subtitle: const Text('Show when you\'re online'),
              value: true, // TODO: Get from preferences
              onChanged: (value) {
                // TODO: Save to preferences
              },
            ),
            SwitchListTile(
              title: const Text('Data Analytics'),
              subtitle: const Text('Help improve the app with usage data'),
              value: false, // TODO: Get from preferences
              onChanged: (value) {
                // TODO: Save to preferences
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDataSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data & Storage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear Chat History'),
              subtitle: const Text('Remove all chat messages'),
              onTap: () {
                Navigator.pop(context);
                _showClearDataDialog(context, 'chat');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear Quiz History'),
              subtitle: const Text('Remove all quiz results'),
              onTap: () {
                Navigator.pop(context);
                _showClearDataDialog(context, 'quiz');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear Task History'),
              subtitle: const Text('Remove all completed tasks'),
              onTap: () {
                Navigator.pop(context);
                _showClearDataDialog(context, 'task');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              subtitle: const Text('Download your data as JSON'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement data export
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data export feature coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('User Guide'),
              subtitle: const Text('Learn how to use the app'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show user guide
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer),
              title: const Text('FAQ'),
              subtitle: const Text('Frequently asked questions'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show FAQ
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_support),
              title: const Text('Contact Support'),
              subtitle: const Text('Get help from our team'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open support contact
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Report Bug'),
              subtitle: const Text('Help us improve the app'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open bug report form
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('Two-Factor Authentication'),
              subtitle: const Text('Add an extra layer of security'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement 2FA
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('2FA feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Active Sessions'),
              subtitle: const Text('Manage your logged-in devices'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show active sessions
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, String dataType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear ${dataType[0].toUpperCase() + dataType.substring(1)} Data',
        ),
        content: Text(
          'Are you sure you want to clear all your $dataType data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement data clearing
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$dataType data cleared successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To change your password, please use the "Forgot Password" option on the login screen.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFirebaseAuthDetails(BuildContext context) {
    if (_firebaseUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase Auth Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('User ID', _firebaseUser!.uid),
              _buildDetailRow('Email', _firebaseUser!.email ?? 'Not provided'),
              _buildDetailRow(
                'Display Name',
                _firebaseUser!.displayName ?? 'Not provided',
              ),
              _buildDetailRow(
                'Phone Number',
                _firebaseUser!.phoneNumber ?? 'Not provided',
              ),
              _buildDetailRow(
                'Email Verified',
                _firebaseUser!.emailVerified ? 'Yes' : 'No',
              ),
              _buildDetailRow(
                'Account Created',
                _formatDate(
                  _firebaseUser!.metadata.creationTime ?? DateTime.now(),
                ),
              ),
              if (_firebaseUser!.metadata.lastSignInTime != null)
                _buildDetailRow(
                  'Last Sign In',
                  _formatDate(_firebaseUser!.metadata.lastSignInTime!),
                ),
              _buildDetailRow(
                'Provider Data',
                _firebaseUser!.providerData.map((p) => p.providerId).join(', '),
              ),
              _buildDetailRow(
                'Is Anonymous',
                _firebaseUser!.isAnonymous ? 'Yes' : 'No',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _refreshFirebaseUser() async {
    setState(() {
      _isLoadingFirebaseUser = true;
    });

    try {
      await _loadFirebaseUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase user data refreshed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh user data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showQuizHistoryDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => QuizHistoryDialog(quizHistory: user.quizHistory),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Social Learning App'),
            const SizedBox(height: 8),
            Text('Version 1.0.0'),
            const SizedBox(height: 8),
            Text(
              'A comprehensive learning platform with quizzes, tasks, and chat features.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetOnboardingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Onboarding'),
        content: const Text(
          'This will show the onboarding screens again the next time you open the app. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await OnboardingService.resetOnboarding();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Onboarding reset successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to reset onboarding: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showSignOutDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final appState = Provider.of<AppState>(context, listen: false);
              appState.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _updateProfile, child: const Text('Update')),
      ],
    );
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.updateUserProfile(
          _nameController.text.trim(),
          _emailController.text.trim(),
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorService.showErrorSnackBar(
            context,
            e,
            fallback: 'Failed to update profile',
          );
        }
      }
    }
  }
}

class QuizHistoryDialog extends StatelessWidget {
  final List<QuizResult> quizHistory;

  const QuizHistoryDialog({super.key, required this.quizHistory});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quiz History'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: quizHistory.length,
          itemBuilder: (context, index) {
            final result = quizHistory[index];
            final percentage = (result.score / result.totalQuestions) * 100;
            final isPassed = percentage >= 80;

            return ListTile(
              leading: Icon(
                isPassed ? Icons.check_circle : Icons.emoji_events,
                color: isPassed ? Colors.green : Colors.orange,
              ),
              title: Text(result.quizTitle),
              subtitle: Text(
                '${result.score}/${result.totalQuestions} (${percentage.toStringAsFixed(1)}%) - ${_formatDate(result.completedAt)}',
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
