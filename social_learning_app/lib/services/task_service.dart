// ignore_for_file: avoid_print

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/task.dart';
import 'firebase_service.dart';

class TaskService {
  static late final FirebaseDatabase _database;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize database with proper configuration
  static Future<void> initializeDatabase() async {
    try {
      // Initialize database with explicit URL
      _database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://ad-mint-default-rtdb.firebaseio.com',
      );

      // Check if database is properly initialized
      if (_database.app == null) {
        print('ERROR: Firebase Database app is null!');
        return;
      }

      // Get database URL from configuration
      final databaseUrl = _database.databaseURL;
      print('Database URL: $databaseUrl');

      // Test basic connection
      final testRef = _database.ref('test');
      await testRef.set({'test': 'connection'});
      await testRef.remove();
      print('Database initialization test successful');
    } catch (e) {
      print('ERROR initializing database: $e');
      print('Stack trace: ${StackTrace.current}');

      // Fallback to default instance
      print('Falling back to default Firebase Database instance...');
      _database = FirebaseDatabase.instance;
    }
  }

  // Get database instance (ensures it's initialized)
  static FirebaseDatabase get database {
    try {
      return _database;
    } catch (e) {
      print('Database not initialized, using default instance');
      return FirebaseDatabase.instance;
    }
  }

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  // Get current user info for debugging
  static Map<String, dynamic>? get currentUserInfo {
    final user = _auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'isEmailVerified': user.emailVerified,
    };
  }

  // Get tasks stream for real-time updates
  static Stream<List<Task>> getTasksStream() {
    final userId = currentUserId;
    if (userId == null) {
      print('No authenticated user found for tasks stream');
      return Stream.value([]);
    }

    print('Setting up tasks stream for user: $userId');
    final tasksRef = database.ref('users/$userId/tasks');

    return tasksRef.onValue
        .map((event) {
          try {
            if (event.snapshot.value == null) {
              print('No tasks found in database for user: $userId');
              return <Task>[];
            }

            final Map<dynamic, dynamic> tasksMap =
                event.snapshot.value as Map<dynamic, dynamic>;
            final List<Task> tasks = [];

            tasksMap.forEach((key, value) {
              try {
                final task = _mapToTask(
                  key.toString(),
                  value as Map<dynamic, dynamic>,
                );
                if (task != null) {
                  tasks.add(task);
                }
              } catch (e) {
                print('Error converting task $key: $e');
              }
            });

            print(
              'Successfully loaded ${tasks.length} tasks for user: $userId',
            );
            // Sort by creation date (newest first)
            tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return tasks;
          } catch (e) {
            print('Error converting tasks from database: $e');
            return <Task>[];
          }
        })
        .handleError((error) {
          print('Error in tasks stream: $error');
          if (error.toString().contains('permission-denied')) {
            print(
              'PERMISSION ERROR: Check Firebase security rules for user: $userId',
            );
            print(
              'Make sure the user is authenticated and has access to: users/$userId/tasks',
            );
          }
          return <Task>[];
        });
  }

  // Get tasks for a specific user
  static Future<List<Task>> getTasks(String userId) async {
    try {
      print('Fetching tasks for user: $userId');
      final tasksRef = database.ref('users/$userId/tasks');
      final snapshot = await tasksRef.get();

      if (snapshot.value == null) {
        print('No tasks found in database for user: $userId');
        return [];
      }

      final Map<dynamic, dynamic> tasksMap =
          snapshot.value as Map<dynamic, dynamic>;
      final List<Task> tasks = [];

      tasksMap.forEach((key, value) {
        try {
          final task = _mapToTask(
            key.toString(),
            value as Map<dynamic, dynamic>,
          );
          if (task != null) {
            tasks.add(task);
          }
        } catch (e) {
          print('Error converting task $key: $e');
        }
      });

      print('Successfully loaded ${tasks.length} tasks for user: $userId');
      // Sort by creation date (newest first)
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } catch (e) {
      print('Error getting tasks: $e');
      if (e.toString().contains('permission-denied')) {
        print(
          'PERMISSION ERROR: Check Firebase security rules for user: $userId',
        );
        print(
          'Make sure the user is authenticated and has access to: users/$userId/tasks',
        );
      }
      return [];
    }
  }

  // Add a new task
  static Future<String?> addTask(Task task) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('No current user ID found');
        return null;
      }

      print('Adding task for user: $userId');
      print('Task data: ${_taskToMap(task)}');

      // Ensure user document exists
      await FirebaseService.ensureUserDocumentExists(userId);

      // Convert task to map
      final taskData = _taskToMap(task);
      taskData['userId'] = userId;
      taskData['createdAt'] = ServerValue.timestamp;
      taskData['updatedAt'] = ServerValue.timestamp;

      print('Prepared task data: $taskData');

      // Add task to user's tasks collection
      final tasksRef = database.ref('users/$userId/tasks');
      print('Database reference: ${tasksRef.path}');

      final newTaskRef = tasksRef.push();
      print('New task reference: ${newTaskRef.path}');

      await newTaskRef.set(taskData);
      print('Task data set successfully');

      // Update user's task count
      await _updateUserTaskCount(userId, 1);

      print(
        'Task added successfully: ${task.title} with ID: ${newTaskRef.key}',
      );
      return newTaskRef.key;
    } catch (e) {
      print('Error adding task: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Update an existing task
  static Future<bool> updateTask(String taskId, Task updatedTask) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final taskData = _taskToMap(updatedTask);
      taskData['updatedAt'] = ServerValue.timestamp;

      final taskRef = database.ref('users/$userId/tasks/$taskId');
      await taskRef.update(taskData);

      print('Task updated successfully: ${updatedTask.title}');
      return true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  // Delete a task
  static Future<bool> deleteTask(String taskId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('ERROR: No current user ID found for delete operation');
        return false;
      }

      print('Attempting to delete task: $taskId for user: $userId');
      final taskRef = database.ref('users/$userId/tasks/$taskId');
      print('Database reference path: ${taskRef.path}');

      // Check if task exists before deleting
      final snapshot = await taskRef.get();
      if (snapshot.value == null) {
        print('WARNING: Task $taskId does not exist in database');
        return false;
      }

      print('Task found, proceeding with deletion...');
      await taskRef.remove();
      print('Task removed from database successfully');

      // Update user's task count
      await _updateUserTaskCount(userId, -1);
      print('User task count updated successfully');

      print('Task deleted successfully: $taskId');
      return true;
    } catch (e) {
      print('ERROR deleting task: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Bulk update task status
  static Future<bool> bulkUpdateTaskStatus(
    List<String> taskIds,
    TaskStatus status,
  ) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final updates = <String, dynamic>{};
      for (final taskId in taskIds) {
        updates['users/$userId/tasks/$taskId/status'] = status.index;
        updates['users/$userId/tasks/$taskId/updatedAt'] =
            ServerValue.timestamp;
      }

      await database.ref().update(updates);
      print('Bulk status update successful for ${taskIds.length} tasks');
      return true;
    } catch (e) {
      print('Error bulk updating task status: $e');
      return false;
    }
  }

  // Bulk delete tasks
  static Future<bool> bulkDeleteTasks(List<String> taskIds) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final updates = <String, dynamic>{};
      for (final taskId in taskIds) {
        updates['users/$userId/tasks/$taskId'] = null; // null removes the node
      }

      await database.ref().update(updates);

      // Update user's task count
      await _updateUserTaskCount(userId, -taskIds.length);

      print('Bulk delete successful for ${taskIds.length} tasks');
      return true;
    } catch (e) {
      print('Error bulk deleting tasks: $e');
      return false;
    }
  }

  // Get task statistics for a user
  static Future<Map<String, int>> getTaskStatistics(String userId) async {
    try {
      final tasks = await getTasks(userId);

      int total = tasks.length;
      int completed = tasks
          .where((task) => task.status == TaskStatus.completed)
          .length;
      int pending = tasks
          .where((task) => task.status == TaskStatus.pending)
          .length;
      int inProgress = tasks
          .where((task) => task.status == TaskStatus.inProgress)
          .length;

      return {
        'total': total,
        'completed': completed,
        'pending': pending,
        'inProgress': inProgress,
      };
    } catch (e) {
      print('Error getting task statistics: $e');
      return {'total': 0, 'completed': 0, 'pending': 0, 'inProgress': 0};
    }
  }

  // Update user's task count
  static Future<void> _updateUserTaskCount(String userId, int increment) async {
    try {
      final userRef = database.ref('users/$userId');
      await userRef.update({
        'tasksCount': ServerValue.increment(increment),
        'lastUpdated': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating user task count: $e');
    }
  }

  // Convert database map to Task model
  static Task? _mapToTask(String id, Map<dynamic, dynamic> data) {
    try {
      // Handle priority conversion - ensure it's an integer
      int priority;
      final priorityData = data['priority'];
      if (priorityData is int) {
        priority = priorityData;
      } else if (priorityData is String) {
        priority = int.tryParse(priorityData) ?? 3;
        print(
          'Converted priority from string: "$priorityData" to int: $priority',
        );
      } else {
        priority = 3; // default priority
        print('Using default priority: $priority (original: $priorityData)');
      }

      // Handle status conversion - ensure it's a valid index
      int statusIndex;
      final statusData = data['status'];
      if (statusData is int) {
        statusIndex = statusData;
      } else if (statusData is String) {
        statusIndex = int.tryParse(statusData) ?? 0;
        print(
          'Converted status from string: "$statusData" to int: $statusIndex',
        );
      } else {
        statusIndex = 0; // default status (pending)
        print('Using default status: $statusIndex (original: $statusData)');
      }

      // Ensure status index is within valid range
      statusIndex = statusIndex.clamp(0, TaskStatus.values.length - 1);

      // Handle dueDate conversion - ensure it's a DateTime
      DateTime dueDate;
      final dueDateData = data['dueDate'];
      if (dueDateData is int) {
        dueDate = DateTime.fromMillisecondsSinceEpoch(dueDateData);
      } else if (dueDateData is String) {
        try {
          dueDate = DateTime.parse(dueDateData);
          print(
            'Converted dueDate from string: "$dueDateData" to DateTime: $dueDate',
          );
        } catch (e) {
          print(
            'Failed to parse dueDate string: "$dueDateData", using default',
          );
          dueDate = DateTime.now();
        }
      } else {
        dueDate = DateTime.now();
        print('Using default dueDate: $dueDate (original: $dueDateData)');
      }

      // Handle createdAt conversion
      DateTime createdAt;
      final createdAtData = data['createdAt'];
      if (createdAtData is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtData);
      } else if (createdAtData is String) {
        try {
          createdAt = DateTime.parse(createdAtData);
          print(
            'Converted createdAt from string: "$createdAtData" to DateTime: $createdAt',
          );
        } catch (e) {
          print(
            'Failed to parse createdAt string: "$createdAtData", using default',
          );
          createdAt = DateTime.now();
        }
      } else {
        createdAt = DateTime.now();
        print('Using default createdAt: $createdAt (original: $createdAtData)');
      }

      // Handle updatedAt conversion
      DateTime? updatedAt;
      final updatedAtData = data['updatedAt'];
      if (updatedAtData is int) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtData);
      } else if (updatedAtData is String) {
        try {
          updatedAt = DateTime.parse(updatedAtData);
          print(
            'Converted updatedAt from string: "$updatedAtData" to DateTime: $updatedAt',
          );
        } catch (e) {
          print(
            'Failed to parse updatedAt string: "$updatedAtData", setting to null',
          );
          updatedAt = null;
        }
      } else if (updatedAtData != null) {
        updatedAt = DateTime.now();
        print('Using default updatedAt: $updatedAt (original: $updatedAtData)');
      }

      return Task(
        id: id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        status: TaskStatus.values[statusIndex],
        priority: priority,
        dueDate: dueDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('Error converting map to task: $e');
      print('Task ID: $id');
      print('Task data: $data');
      return null;
    }
  }

  // Convert Task model to database map
  static Map<String, dynamic> _taskToMap(Task task) {
    return {
      'title': task.title,
      'description': task.description,
      'status': task.status.index,
      'priority': task.priority,
      'dueDate': task.dueDate.millisecondsSinceEpoch,
      'createdAt': task.createdAt.millisecondsSinceEpoch,
      if (task.updatedAt != null)
        'updatedAt': task.updatedAt!.millisecondsSinceEpoch,
    };
  }

  // Fix date format issues in existing tasks
  static Future<void> fixDateFormats(String userId) async {
    try {
      final tasksRef = database.ref('users/$userId/tasks');
      final snapshot = await tasksRef.get();

      if (snapshot.value == null) {
        print('No tasks found for user: $userId');
        return;
      }

      final Map<dynamic, dynamic> tasksMap =
          snapshot.value as Map<dynamic, dynamic>;
      final updates = <String, dynamic>{};

      tasksMap.forEach((key, value) {
        try {
          final taskData = value as Map<dynamic, dynamic>;
          bool needsUpdate = false;

          // Fix dueDate if it's a string
          if (taskData['dueDate'] is String) {
            try {
              final parsedDate = DateTime.parse(taskData['dueDate'] as String);
              updates['users/$userId/tasks/$key/dueDate'] =
                  parsedDate.millisecondsSinceEpoch;
              needsUpdate = true;
              print(
                'Fixed dueDate for task $key: ${taskData['dueDate']} -> ${parsedDate.millisecondsSinceEpoch}',
              );
            } catch (e) {
              print(
                'Failed to parse dueDate for task $key: ${taskData['dueDate']}',
              );
            }
          }

          // Fix createdAt if it's a string
          if (taskData['createdAt'] is String) {
            try {
              final parsedDate = DateTime.parse(
                taskData['createdAt'] as String,
              );
              updates['users/$userId/tasks/$key/createdAt'] =
                  parsedDate.millisecondsSinceEpoch;
              needsUpdate = true;
              print(
                'Fixed createdAt for task $key: ${taskData['createdAt']} -> ${parsedDate.millisecondsSinceEpoch}',
              );
            } catch (e) {
              print(
                'Failed to parse createdAt for task $key: ${taskData['createdAt']}',
              );
            }
          }

          // Fix updatedAt if it's a string
          if (taskData['updatedAt'] is String) {
            try {
              final parsedDate = DateTime.parse(
                taskData['updatedAt'] as String,
              );
              updates['users/$userId/tasks/$key/updatedAt'] =
                  parsedDate.millisecondsSinceEpoch;
              needsUpdate = true;
              print(
                'Fixed updatedAt for task $key: ${taskData['updatedAt']} -> ${parsedDate.millisecondsSinceEpoch}',
              );
            } catch (e) {
              print(
                'Failed to parse updatedAt for task $key: ${taskData['updatedAt']}',
              );
            }
          }

          // Fix status if it's a string
          if (taskData['status'] is String) {
            final statusString = taskData['status'] as String;
            int statusIndex;
            switch (statusString.toLowerCase()) {
              case 'pending':
                statusIndex = 0;
                break;
              case 'inprogress':
              case 'in_progress':
                statusIndex = 1;
                break;
              case 'completed':
              case 'done':
                statusIndex = 2;
                break;
              default:
                statusIndex = 0;
            }
            updates['users/$userId/tasks/$key/status'] = statusIndex;
            needsUpdate = true;
            print('Fixed status for task $key: $statusString -> $statusIndex');
          }
        } catch (e) {
          print('Error processing task $key: $e');
        }
      });

      if (updates.isNotEmpty) {
        await database.ref().update(updates);
        print('Date formats fixed successfully for ${updates.length} fields');
      } else {
        print('No date format issues found');
      }
    } catch (e) {
      print('Error fixing date formats: $e');
    }
  }

  // Debug: Check data types in database
  static Future<void> debugTaskDataTypes(String userId) async {
    try {
      final tasksRef = database.ref('users/$userId/tasks');
      final snapshot = await tasksRef.limitToFirst(5).get();

      if (snapshot.value == null) {
        print('No tasks found for user: $userId');
        return;
      }

      final Map<dynamic, dynamic> tasksMap =
          snapshot.value as Map<dynamic, dynamic>;

      print('=== Debug: Task Data Types ===');
      tasksMap.forEach((key, value) {
        final data = value as Map<dynamic, dynamic>;
        print('Task ID: $key');
        print(
          '  Priority: ${data['priority']} (${data['priority'].runtimeType})',
        );
        print('  Status: ${data['status']} (${data['status'].runtimeType})');
        print('  Title: ${data['title']} (${data['title'].runtimeType})');
        print('---');
      });
    } catch (e) {
      print('Error debugging task data types: $e');
    }
  }

  // Search tasks by query
  static Future<List<Task>> searchTasks(String query) async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final allTasks = await getTasks(userId);

      if (query.isEmpty) return allTasks;

      return allTasks.where((task) {
        final searchQuery = query.toLowerCase();
        return task.title.toLowerCase().contains(searchQuery) ||
            task.description.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Error searching tasks: $e');
      return [];
    }
  }

  // Get tasks by status
  static Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final allTasks = await getTasks(userId);
      return allTasks.where((task) => task.status == status).toList();
    } catch (e) {
      print('Error getting tasks by status: $e');
      return [];
    }
  }

  // Get overdue tasks
  static Future<List<Task>> getOverdueTasks() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final now = DateTime.now();
      final allTasks = await getTasks(userId);

      return allTasks
          .where(
            (task) =>
                task.dueDate.isBefore(now) &&
                task.status != TaskStatus.completed,
          )
          .toList();
    } catch (e) {
      print('Error getting overdue tasks: $e');
      return [];
    }
  }

  // Get tasks due today
  static Future<List<Task>> getTasksDueToday() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final allTasks = await getTasks(userId);

      return allTasks
          .where(
            (task) =>
                task.dueDate.isAfter(today) && task.dueDate.isBefore(tomorrow),
          )
          .toList();
    } catch (e) {
      print('Error getting tasks due today: $e');
      return [];
    }
  }

  // Get tasks by priority
  static Future<List<Task>> getTasksByPriority(int priority) async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final allTasks = await getTasks(userId);
      return allTasks.where((task) => task.priority == priority).toList();
    } catch (e) {
      print('Error getting tasks by priority: $e');
      return [];
    }
  }

  // Sync tasks with local storage (for offline support)
  static Future<void> syncTasksWithLocal(List<Task> localTasks) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      // Ensure user document exists
      await FirebaseService.ensureUserDocumentExists(userId);

      final updates = <String, dynamic>{};

      for (final task in localTasks) {
        final taskData = _taskToMap(task);
        taskData['userId'] = userId;
        taskData['createdAt'] = task.createdAt.millisecondsSinceEpoch;
        taskData['updatedAt'] =
            (task.updatedAt ?? task.createdAt).millisecondsSinceEpoch;

        updates['users/$userId/tasks/${task.id}'] = taskData;
      }

      await database.ref().update(updates);
      print(
        'Synced ${localTasks.length} tasks with Firebase Realtime Database',
      );
    } catch (e) {
      print('Error syncing tasks with Firebase: $e');
    }
  }

  // Test database connection
  static Future<bool> testDatabaseConnection() async {
    try {
      print('Testing Firebase Realtime Database connection...');
      print('Database app: ${database.app?.name}');
      print('Database URL: ${database.databaseURL}');

      // Check if database is properly initialized
      if (database.app == null) {
        print('ERROR: Database app is null!');
        return false;
      }

      // Try to write a test value
      final testRef = database.ref('test_connection');
      print('Test reference path: ${testRef.path}');

      await testRef.set({
        'timestamp': ServerValue.timestamp,
        'message': 'Connection test successful',
      });
      print('Test data written successfully');

      // Try to read it back
      final snapshot = await testRef.get();
      if (snapshot.value != null) {
        print('Database connection test successful');
        print('Read data: ${snapshot.value}');

        // Clean up test data
        await testRef.remove();
        print('Test data cleaned up');
        return true;
      } else {
        print('Database connection test failed - could not read data');
        return false;
      }
    } catch (e) {
      print('Database connection test failed: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
}
