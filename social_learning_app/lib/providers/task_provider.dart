// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import '../services/task_service.dart';

// Task filter enum
enum TaskFilter { all, pending, done }

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  TaskFilter _currentFilter = TaskFilter.all;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Map<String, dynamic> _statistics = {};
  bool _isSelectionMode = false;
  Set<String> _selectedTaskIds = {};

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get filteredTasks => _filteredTasks;
  TaskFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get statistics => _statistics;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedTaskIds => _selectedTaskIds;
  int get selectedCount => _selectedTaskIds.length;
  bool get hasSelectedTasks => _selectedTaskIds.isNotEmpty;

  // Initialize provider
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _loadTasks(user.uid);
      await _loadStatistics(user.uid);
      _startRealtimeUpdates(user.uid);
    }
  }

  // Load tasks from Firebase
  Future<void> _loadTasks(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final tasks = await TaskService.getTasks(userId);
      _tasks = tasks;
      _applyFilters();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load tasks: $e');
      _setLoading(false);
    }
  }

  // Start real-time updates
  void _startRealtimeUpdates(String userId) {
    TaskService.getTasksStream().listen(
      (tasks) {
        // Only update if we have tasks (avoid clearing existing tasks on error)
        if (tasks.isNotEmpty || _tasks.isEmpty) {
          _tasks = tasks;
          _applyFilters();
          notifyListeners();
        }
      },
      onError: (error) {
        // ignore: avoid_print
        print('Real-time update error: $error');
        // Don't set error for stream issues, just log them
        // This prevents the UI from showing errors for temporary connection issues
      },
    );
  }

  // Load task statistics
  Future<void> _loadStatistics(String userId) async {
    try {
      final stats = await TaskService.getTaskStatistics(userId);
      _statistics = stats;
      notifyListeners();
    } catch (e) {
      print('Failed to load statistics: $e');
    }
  }

  // Add new task
  Future<bool> addTask(Task task) async {
    try {
      _setLoading(true);
      _clearError();

      final taskId = await TaskService.addTask(task);

      if (taskId != null) {
        // Create a new task with the proper ID from Firebase
        final newTask = task.copyWith(id: taskId);

        // Add to local list immediately for better UX
        _tasks.insert(0, newTask);
        _applyFilters();
        notifyListeners();

        _setLoading(false);
        return true;
      } else {
        _setError('Failed to add task: No task ID returned');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to add task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update existing task
  Future<bool> updateTask(String taskId, Task task) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await TaskService.updateTask(taskId, task);

      if (success) {
        // Update local task immediately for better UX
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = task;
          _applyFilters();
          notifyListeners();
        }

        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update task');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to update task: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update task status
  Future<bool> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      // Create a copy of the task with updated status
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(status: status);

      final success = await TaskService.updateTask(taskId, updatedTask);

      if (success) {
        // Update local task immediately for better UX
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = updatedTask;
          _applyFilters();
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _setError('Failed to update task status: $e');
      return false;
    }
  }

  // Delete task
  Future<bool> deleteTask(String taskId) async {
    try {
      final success = await TaskService.deleteTask(taskId);

      if (success) {
        // Remove from local list immediately for better UX
        _tasks.removeWhere((task) => task.id == taskId);
        _applyFilters();
        notifyListeners();
        return true;
      } else {
        _setError('Failed to delete task');
        return false;
      }
    } catch (e) {
      _setError('Failed to delete task: $e');
      return false;
    }
  }

  // Bulk delete tasks
  Future<bool> bulkDeleteTasks() async {
    if (_selectedTaskIds.isEmpty) return false;

    try {
      _setLoading(true);
      _clearError();

      final success = await TaskService.bulkDeleteTasks(
        _selectedTaskIds.toList(),
      );

      if (success) {
        // Remove deleted tasks from local list
        _tasks.removeWhere((task) => _selectedTaskIds.contains(task.id));
        _applyFilters();

        // Clear selection mode
        exitSelectionMode();

        _setLoading(false);
        return true;
      } else {
        _setError('Failed to delete tasks');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete tasks: $e');
      _setLoading(false);
      return false;
    }
  }

  // Bulk update task status
  Future<bool> bulkUpdateTaskStatus(TaskStatus status) async {
    if (_selectedTaskIds.isEmpty) return false;

    try {
      _setLoading(true);
      _clearError();

      final success = await TaskService.bulkUpdateTaskStatus(
        _selectedTaskIds.toList(),
        status,
      );

      if (success) {
        // Update local tasks immediately for better UX
        for (final taskId in _selectedTaskIds) {
          final index = _tasks.indexWhere((t) => t.id == taskId);
          if (index != -1) {
            _tasks[index] = _tasks[index].copyWith(status: status);
          }
        }
        _applyFilters();

        // Clear selection mode
        exitSelectionMode();

        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update task status');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to update task status: $e');
      _setLoading(false);
      return false;
    }
  }

  // Set filter
  void setFilter(TaskFilter filter) {
    _currentFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters and search
  void _applyFilters() {
    List<Task> filtered = _tasks;

    // Apply status filter
    switch (_currentFilter) {
      case TaskFilter.all:
        // No filtering needed
        break;
      case TaskFilter.pending:
        filtered = filtered
            .where(
              (task) =>
                  task.status == TaskStatus.pending ||
                  task.status == TaskStatus.inProgress,
            )
            .toList();
        break;
      case TaskFilter.done:
        filtered = filtered
            .where((task) => task.status == TaskStatus.completed)
            .toList();
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        final query = _searchQuery.toLowerCase();
        return task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query);
      }).toList();
    }

    _filteredTasks = filtered;
  }

  // Refresh tasks
  Future<void> refreshTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        _clearError();
        await _loadTasks(user.uid);
        await _loadStatistics(user.uid);
      } catch (e) {
        _setError('Failed to refresh tasks: $e');
      }
    }
  }

  // Force refresh from Firebase (useful for debugging)
  Future<void> forceRefreshFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        _setLoading(true);
        _clearError();

        // Get fresh data from Firebase
        final freshTasks = await TaskService.getTasks(user.uid);
        _tasks = freshTasks;
        _applyFilters();

        // Reload statistics
        await _loadStatistics(user.uid);

        _setLoading(false);
        print('Force refreshed ${freshTasks.length} tasks from Firebase');
      } catch (e) {
        _setError('Failed to force refresh: $e');
        _setLoading(false);
      }
    }
  }

  // Fix data format issues in existing tasks
  Future<void> fixDataFormats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await TaskService.fixDateFormats(user.uid);
        await refreshTasks(); // Reload tasks after fixing
      } catch (e) {
        _setError('Failed to fix data formats: $e');
      }
    }
  }

  // Selection mode management
  void enterSelectionMode() {
    _isSelectionMode = true;
    _selectedTaskIds.clear();
    notifyListeners();
  }

  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedTaskIds.clear();
    notifyListeners();
  }

  void toggleTaskSelection(String taskId) {
    if (_selectedTaskIds.contains(taskId)) {
      _selectedTaskIds.remove(taskId);
    } else {
      _selectedTaskIds.add(taskId);
    }

    if (_selectedTaskIds.isEmpty) {
      exitSelectionMode();
    }

    notifyListeners();
  }

  void selectAllTasks() {
    _selectedTaskIds = _filteredTasks.map((task) => task.id).toSet();
    notifyListeners();
  }

  void clearSelection() {
    _selectedTaskIds.clear();
    notifyListeners();
  }

  // Get tasks by priority
  List<Task> getTasksByPriority(int priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  // Get overdue tasks
  List<Task> getOverdueTasks() {
    return _tasks.where((task) => task.isOverdue).toList();
  }

  // Get upcoming tasks
  List<Task> getUpcomingTasks() {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));

    return _tasks
        .where(
          (task) =>
              task.dueDate.isAfter(now) &&
              task.dueDate.isBefore(weekFromNow) &&
              task.status != TaskStatus.completed,
        )
        .toList();
  }

  // Get tasks due today
  List<Task> getTasksDueToday() {
    final now = DateTime.now();
    return _tasks
        .where(
          (task) =>
              task.dueDate.year == now.year &&
              task.dueDate.month == now.month &&
              task.dueDate.day == now.day,
        )
        .toList();
  }

  // Get tasks due soon (within 3 days)
  List<Task> getTasksDueSoon() {
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));

    return _tasks
        .where(
          (task) =>
              task.dueDate.isAfter(now) &&
              task.dueDate.isBefore(threeDaysFromNow) &&
              task.status != TaskStatus.completed,
        )
        .toList();
  }

  // Clear error
  void _clearError() {
    _error = null;
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear all data (for sign out)
  void clearData() {
    _tasks.clear();
    _filteredTasks.clear();
    _statistics.clear();
    _error = null;
    _isLoading = false;
    _isSelectionMode = false;
    _selectedTaskIds.clear();
    _searchQuery = '';
    _currentFilter = TaskFilter.all;
    notifyListeners();
  }

  // Dispose
}
