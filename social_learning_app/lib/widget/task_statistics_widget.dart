import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class TaskStatisticsWidget extends StatelessWidget {
  const TaskStatisticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: const _TaskStatisticsContent(),
    );
  }
}

// Optimized content widget that only rebuilds when necessary
class _TaskStatisticsContent extends StatelessWidget {
  const _TaskStatisticsContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary.withOpacity(0.05), colorScheme.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Static content that doesn't need rebuilding
          _buildHeader(theme, colorScheme),
          const SizedBox(height: 20),

          // Statistics Grid - Only rebuilds when task data changes
          const _StatisticsGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.analytics_outlined,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Your productivity at a glance',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid();

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Efficiently calculate statistics in a single pass
        final stats = _calculateTaskStatistics(taskProvider.tasks);

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total',
                value: stats.total.toString(),
                icon: Icons.task_alt,
                color: Colors.blue,
                subtitle: 'All tasks',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Completed',
                value: stats.completed.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
                subtitle: '${stats.completionPercentage}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Pending',
                value: stats.pending.toString(),
                icon: Icons.schedule,
                color: Colors.orange,
                subtitle: 'Awaiting',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'In Progress',
                value: stats.inProgress.toString(),
                icon: Icons.play_circle_fill,
                color: Colors.purple,
                subtitle: 'Active',
              ),
            ),
          ],
        );
      },
    );
  }

  // Efficient statistics calculation in a single pass
  _TaskStats _calculateTaskStatistics(List<Task> tasks) {
    int completed = 0;
    int pending = 0;
    int inProgress = 0;

    for (final task in tasks) {
      switch (task.status) {
        case TaskStatus.completed:
          completed++;
          break;
        case TaskStatus.pending:
          pending++;
          break;
        case TaskStatus.inProgress:
          inProgress++;
          break;
      }
    }

    final total = tasks.length;
    final completionPercentage = total > 0
        ? ((completed / total) * 100).round()
        : 0;

    return _TaskStats(
      total: total,
      completed: completed,
      pending: pending,
      inProgress: inProgress,
      completionPercentage: completionPercentage,
    );
  }
}

// Immutable statistics data class for better performance
class _TaskStats {
  final int total;
  final int completed;
  final int pending;
  final int inProgress;
  final int completionPercentage;

  const _TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.inProgress,
    required this.completionPercentage,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Value
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
