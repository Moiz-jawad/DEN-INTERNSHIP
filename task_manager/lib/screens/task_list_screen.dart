// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import 'add_edit_task_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        title: const Text(
          'My Tasks',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'all':
                      taskProvider.filterByCategory(null);
                      break;
                    case 'work':
                      taskProvider.filterByCategory(Category.work);
                      break;
                    case 'personal':
                      taskProvider.filterByCategory(Category.personal);
                      break;
                    case 'study':
                      taskProvider.filterByCategory(Category.study);
                      break;
                    case 'health':
                      taskProvider.filterByCategory(Category.health);
                      break;
                    case 'shopping':
                      taskProvider.filterByCategory(Category.shopping);
                      break;
                    case 'toggle_completed':
                      taskProvider.toggleShowCompleted();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'all', child: Text('All Categories')),
                  const PopupMenuItem(value: 'work', child: Text('Work')),
                  const PopupMenuItem(
                      value: 'personal', child: Text('Personal')),
                  const PopupMenuItem(value: 'study', child: Text('Study')),
                  const PopupMenuItem(value: 'health', child: Text('Health')),
                  const PopupMenuItem(
                      value: 'shopping', child: Text('Shopping')),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'toggle_completed',
                    child: Text(taskProvider.showCompleted
                        ? 'Hide Completed'
                        : 'Show Completed'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first task',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            'Total',
                            taskProvider.pendingTasks.length.toString(),
                            Colors.blue,
                            Icons.list_alt)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildStatCard(
                            'Completed',
                            taskProvider.completedTasks.length.toString(),
                            Colors.green,
                            Icons.check_circle)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildStatCard(
                            'High Priority',
                            taskProvider.highPriorityTasks.length.toString(),
                            Colors.red,
                            Icons.priority_high)),
                  ],
                ),
              ),
              Expanded(
                child: AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: taskProvider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = taskProvider.tasks[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50,
                          child: FadeInAnimation(
                            child: TaskCard(
                              task: task,
                              onTap: () => _navigateToEditTask(context, task),
                              onToggleComplete: () =>
                                  taskProvider.toggleTaskCompletion(task),
                              onDelete: () =>
                                  _showDeleteConfirmation(context, task),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor,
        onPressed: () => _navigateToAddTask(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  void _navigateToAddTask(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AddEditTaskScreen()));
  }

  void _navigateToEditTask(BuildContext context, Task task) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: task)));
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Provider.of<TaskProvider>(context, listen: false)
                  .deleteTask(task.id!);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
