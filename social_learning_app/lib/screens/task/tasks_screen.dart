// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../widget/task_statistics_widget.dart';
import '../../widget/enhanced_task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSearchVisible = false;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize task provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().initialize();
      _fadeController.forward();
      _slideController.forward();
    });

    // Listen to scroll for FAB visibility
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() => _isFabVisible = false);
        _scaleController.reverse();
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() => _isFabVisible = true);
        _scaleController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 130,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: FadeTransition(
                      opacity: _fadeController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task Manager',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Organize your day, achieve your goals',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Search Button
              AnimatedBuilder(
                animation: _slideController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - _slideController.value)),
                    child: Opacity(
                      opacity: _slideController.value,
                      child: IconButton(
                        icon: Icon(
                          _isSearchVisible ? Icons.close : Icons.search,
                          color: colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearchVisible = !_isSearchVisible;
                            if (!_isSearchVisible) {
                              _searchController.clear();
                              context.read<TaskProvider>().setSearchQuery('');
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              // More Options
              AnimatedBuilder(
                animation: _slideController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - _slideController.value)),
                    child: Opacity(
                      opacity: _slideController.value,
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: colorScheme.primary),
                        onSelected: _handleMenuAction,
                        itemBuilder: (context) => [
                          _buildMenuItem(
                            'select_all',
                            Icons.select_all,
                            'Select All',
                            colorScheme.primary,
                          ),
                          _buildMenuItem(
                            'bulk_complete',
                            Icons.check_circle,
                            'Mark Selected Complete',
                            Colors.green,
                          ),
                          _buildMenuItem(
                            'bulk_delete',
                            Icons.delete_sweep,
                            'Delete Selected',
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.primary.withOpacity(0.1),
                  ),
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Completed'),
                  ],
                  onTap: (index) {
                    final filter = TaskFilter.values[index];
                    context.read<TaskProvider>().setFilter(filter);
                  },
                ),
              ),
            ),
          ),

          // Search Bar and Debug Tools
          if (_isSearchVisible)
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (query) {
                          context.read<TaskProvider>().setSearchQuery(query);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Debug buttons - remove these in production
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await context
                                  .read<TaskProvider>()
                                  .forceRefreshFromFirebase();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Force refreshed from Firebase!',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Force Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await context
                                  .read<TaskProvider>()
                                  .fixDataFormats();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Data formats fixed!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Fix Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.errorContainer,
                              foregroundColor: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Test database connection button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final success =
                              await TaskService.testDatabaseConnection();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Database connection successful!'
                                    : 'Database connection failed!',
                              ),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.wifi),
                        label: const Text('Test Database Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Check authentication status button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final userInfo = TaskService.currentUserInfo;
                          final isAuth = TaskService.isAuthenticated;
                          final userId = TaskService.currentUserId;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isAuth
                                    ? 'Authenticated: ${userInfo?['email'] ?? 'No email'} (UID: $userId)'
                                    : 'Not authenticated!',
                              ),
                              backgroundColor: isAuth
                                  ? Colors.green
                                  : Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );

                          // Also print to console for debugging
                          print('=== Authentication Status ===');
                          print('Is Authenticated: $isAuth');
                          print('User ID: $userId');
                          print('User Info: $userInfo');
                          print('============================');
                        },
                        icon: const Icon(Icons.person),
                        label: const Text('Check Auth Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.tertiary,
                          foregroundColor: colorScheme.onTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Test delete functionality button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final tasks = context.read<TaskProvider>().tasks;
                          if (tasks.isNotEmpty) {
                            final firstTask = tasks.first;
                            print(
                              'Testing delete for task: ${firstTask.title}',
                            );
                            _deleteTask(context, firstTask);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No tasks available to test delete',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Test Delete First Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Statistics Widget
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeController,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _fadeController,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: const TaskStatisticsWidget(),
              ),
            ),
          ),

          // Task List
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (taskProvider.isLoading) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: colorScheme.primary,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading tasks...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (taskProvider.error != null) {
                return SliverFillRemaining(
                  child: _buildErrorWidget(
                    taskProvider.error!,
                    theme,
                    colorScheme,
                  ),
                );
              }

              if (taskProvider.filteredTasks.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(theme, colorScheme),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final task = taskProvider.filteredTasks[index];
                    return AnimatedBuilder(
                      animation: _fadeController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeController,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: Offset(0, 0.3 + (index * 0.1)),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _fadeController,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: 16,
                                top: index == 0 ? 8 : 0,
                              ),
                              child: EnhancedTaskCard(
                                task: task,
                                isSelected: taskProvider.selectedTaskIds
                                    .contains(task.id),
                                onTap: () => _showTaskDetails(context, task),
                                onEdit: () =>
                                    _showEditTaskDialog(context, task),
                                onDelete: () => _deleteTask(context, task),
                                onToggleSelection: taskProvider.isSelectionMode
                                    ? () => taskProvider.toggleTaskSelection(
                                        task.id,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }, childCount: taskProvider.filteredTasks.length),
                ),
              );
            },
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (taskProvider.isSelectionMode) {
                return ScaleTransition(
                  scale: _scaleController,
                  child: FloatingActionButton.extended(
                    onPressed: taskProvider.hasSelectedTasks
                        ? () => _showBulkActions(context)
                        : null,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 8,
                    icon: const Icon(Icons.more_vert),
                    label: Text('${taskProvider.selectedCount} selected'),
                  ),
                );
              }

              return ScaleTransition(
                scale: _scaleController,
                child: FloatingActionButton(
                  onPressed: () => _showAddTaskDialog(context),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 8,
                  child: const Icon(Icons.add, size: 28),
                ),
              );
            },
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(
    String error,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<TaskProvider>().refreshTasks(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.task_alt, size: 64, color: colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'No tasks yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first task to get started with organizing your day',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddTaskDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create Task'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    final taskProvider = context.read<TaskProvider>();

    switch (action) {
      case 'select_all':
        taskProvider.enterSelectionMode();
        taskProvider.selectAllTasks();
        break;
      case 'bulk_complete':
        if (taskProvider.hasSelectedTasks) {
          _showBulkActions(context);
        }
        break;
      case 'bulk_delete':
        if (taskProvider.hasSelectedTasks) {
          _showBulkActions(context);
        }
        break;
    }
  }

  void _showBulkActions(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '${taskProvider.selectedCount} tasks selected',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mark as complete
                    _buildBulkActionTile(
                      context,
                      Icons.check_circle,
                      'Mark as Complete',
                      Colors.green,
                      () {
                        Navigator.pop(context);
                        taskProvider.bulkUpdateTaskStatus(TaskStatus.completed);
                      },
                    ),

                    // Mark as in progress
                    _buildBulkActionTile(
                      context,
                      Icons.play_circle_outline,
                      'Mark as In Progress',
                      Colors.blue,
                      () {
                        Navigator.pop(context);
                        taskProvider.bulkUpdateTaskStatus(
                          TaskStatus.inProgress,
                        );
                      },
                    ),

                    // Delete selected
                    _buildBulkActionTile(
                      context,
                      Icons.delete,
                      'Delete Selected',
                      Colors.red,
                      () {
                        Navigator.pop(context);
                        _showBulkDeleteConfirmation(context);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          taskProvider.exitSelectionMode();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulkActionTile(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showBulkDeleteConfirmation(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Tasks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${taskProvider.selectedCount} selected tasks? This action cannot be undone.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              taskProvider.bulkDeleteTasks();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddTaskDialog());
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => EditTaskDialog(task: task),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailsDialog(task: task),
    );
  }

  void _deleteTask(BuildContext context, Task task) {
    print('_deleteTask called for task: ${task.title} with ID: ${task.id}');
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Deleting task...'),
                    duration: Duration(seconds: 1),
                  ),
                );

                try {
                  // Delete the task
                  final success = await context.read<TaskProvider>().deleteTask(
                    task.id,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Task "${task.title}" deleted successfully!',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Failed to delete task. Please try again.',
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error deleting task: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting task: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

// Add Task Dialog
class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedPriority = 3;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Create New Task',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInputField(
                      controller: _titleController,
                      label: 'Task Title',
                      icon: Icons.title,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a task title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _descriptionController,
                      label: 'Description',
                      icon: Icons.description,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDateField(colorScheme)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPriorityField(colorScheme)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Task'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDateField(ColorScheme colorScheme) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: TextStyle(color: colorScheme.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityField(ColorScheme colorScheme) {
    return DropdownButtonFormField<int>(
      value: _selectedPriority,
      decoration: InputDecoration(
        labelText: 'Priority',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      items: [1, 2, 3, 4, 5].map((priority) {
        return DropdownMenuItem(
          value: priority,
          child: Text('Priority $priority'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPriority = value!;
        });
      },
    );
  }

  void _addTask() async {
    if (_formKey.currentState!.validate()) {
      final taskProvider = context.read<TaskProvider>();
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _selectedDate,
        priority: _selectedPriority,
      );

      final success = await taskProvider.addTask(task);
      if (success) {
        Navigator.pop(context);
      }
    }
  }
}

// Edit Task Dialog
class EditTaskDialog extends StatefulWidget {
  final Task task;

  const EditTaskDialog({super.key, required this.task});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late int _selectedPriority;
  late TaskStatus _selectedStatus;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _selectedDate = widget.task.dueDate;
    _selectedPriority = widget.task.priority;
    _selectedStatus = widget.task.status;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'Edit Task',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputField(
                  controller: _titleController,
                  label: 'Task Title',
                  icon: Icons.title,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Status dropdown
                DropdownButtonFormField<TaskStatus>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  items: TaskStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_getStatusText(status)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _buildDateField(colorScheme)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPriorityField(colorScheme)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _updateTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildDateField(ColorScheme colorScheme) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: TextStyle(color: colorScheme.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityField(ColorScheme colorScheme) {
    return DropdownButtonFormField<int>(
      value: _selectedPriority,
      decoration: InputDecoration(
        labelText: 'Priority',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      items: [1, 2, 3, 4, 5].map((priority) {
        return DropdownMenuItem(
          value: priority,
          child: Text('Priority $priority'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPriority = value!;
        });
      },
    );
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  void _updateTask() async {
    final taskProvider = context.read<TaskProvider>();
    final updatedTask = widget.task.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      status: _selectedStatus,
      dueDate: _selectedDate,
      priority: _selectedPriority,
    );

    final success = await taskProvider.updateTask(widget.task.id, updatedTask);
    if (success) {
      Navigator.pop(context);
    }
  }
}

// Task Details Dialog
class TaskDetailsDialog extends StatelessWidget {
  final Task task;

  const TaskDetailsDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        task.title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.description.isNotEmpty) ...[
            Text(
              'Description',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildDetailRow('Status', task.statusText, task.statusColor),
          _buildDetailRow(
            'Due Date',
            _formatDate(task.dueDate),
            task.isOverdue
                ? Colors.red
                : colorScheme.onSurface.withOpacity(0.7),
          ),
          _buildDetailRow('Priority', task.priorityText, task.priorityColor),
          _buildDetailRow(
            'Created',
            _formatDate(task.createdAt),
            colorScheme.onSurface.withOpacity(0.7),
          ),

          if (task.updatedAt != null)
            _buildDetailRow(
              'Updated',
              _formatDate(task.updatedAt!),
              colorScheme.onSurface.withOpacity(0.7),
            ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: color, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
