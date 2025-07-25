import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  Category? _selectedCategory;
  bool _showCompleted = true;

  List<Task> get tasks => _filteredTasks;
  Category? get selectedCategory => _selectedCategory;
  bool get showCompleted => _showCompleted;

  TaskProvider() {
    loadTasks();
  }

  Future<void> loadTasks() async {
    _tasks = await DatabaseService.instance.getAllTasks();
    _applyFilters();
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await DatabaseService.instance.insertTask(task);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await DatabaseService.instance.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await DatabaseService.instance.deleteTask(id);
    await loadTasks();
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask);
  }

  void filterByCategory(Category? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void toggleShowCompleted() {
    _showCompleted = !_showCompleted;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTasks = _tasks.where((task) {
      bool categoryMatch = _selectedCategory == null || task.category == _selectedCategory;
      bool completedMatch = _showCompleted || !task.isCompleted;
      return categoryMatch && completedMatch;
    }).toList();
  }

  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();
  List<Task> get pendingTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get highPriorityTasks => _tasks.where((task) => task.priority == Priority.high && !task.isCompleted).toList();
}
