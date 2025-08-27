// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../models/task.dart';

class EnhancedTaskCard extends StatefulWidget {
  final Task task;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleSelection;

  const EnhancedTaskCard({
    super.key,
    required this.task,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleSelection,
  });

  @override
  State<EnhancedTaskCard> createState() => _EnhancedTaskCardState();
}

class _EnhancedTaskCardState extends State<EnhancedTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? colorScheme.primary.withOpacity(0.1)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isSelected
                      ? colorScheme.primary
                      : _isHovered
                      ? colorScheme.primary.withOpacity(0.3)
                      : colorScheme.outline.withOpacity(0.1),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.05 + (_elevationAnimation.value * 0.01),
                    ),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value * 0.5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title, status, and selection
                        Row(
                          children: [
                            if (widget.onToggleSelection != null)
                              _buildSelectionCheckbox(colorScheme),

                            if (widget.onToggleSelection != null)
                              const SizedBox(width: 16),

                            Expanded(
                              child: Text(
                                widget.task.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration:
                                      widget.task.status == TaskStatus.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color:
                                      widget.task.status == TaskStatus.completed
                                      ? colorScheme.onSurface.withOpacity(0.6)
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            _buildStatusChip(context, colorScheme),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Description
                        if (widget.task.description.isNotEmpty) ...[
                          Text(
                            widget.task.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              decoration:
                                  widget.task.status == TaskStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Task details row
                        Row(
                          children: [
                            // Due date
                            Expanded(
                              child: _buildDetailItem(
                                context,
                                Icons.calendar_today,
                                _formatDueDate(widget.task.dueDate),
                                widget.task.isOverdue
                                    ? Colors.red
                                    : colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),

                            const SizedBox(width: 20),

                            // Priority
                            Expanded(
                              child: _buildDetailItem(
                                context,
                                Icons.priority_high,
                                widget.task.priorityText,
                                widget.task.priorityColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Action buttons
                        if (widget.onEdit != null || widget.onDelete != null)
                          Row(
                            children: [
                              if (widget.onEdit != null) ...[
                                Expanded(
                                  child: _buildActionButton(
                                    context,
                                    Icons.edit,
                                    'Edit',
                                    colorScheme.primary,
                                    widget.onEdit!,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],

                              if (widget.onDelete != null)
                                Expanded(
                                  child: _buildActionButton(
                                    context,
                                    Icons.delete,
                                    'Delete',
                                    Colors.red,
                                    () {
                                      print(
                                        'Delete button pressed for task: ${widget.task.title}',
                                      );
                                      _showDeleteConfirmation(context);
                                    },
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionCheckbox(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: widget.onToggleSelection,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isSelected ? colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: widget.isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: widget.isSelected
            ? Icon(Icons.check, color: colorScheme.onPrimary, size: 18)
            : null,
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.task.statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.task.statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(widget.task.status),
            color: widget.task.statusColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            widget.task.statusText,
            style: TextStyle(
              color: widget.task.statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.completed:
        return Icons.check_circle;
      default:
        return Icons.schedule;
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    print('_showDeleteConfirmation called for task: ${widget.task.title}');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = await showDialog<bool>(
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
              'Delete Task',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${widget.task.title}"?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

    // If user confirmed deletion, call the onDelete callback
    if (result == true && widget.onDelete != null) {
      print('User confirmed deletion, calling onDelete callback');
      widget.onDelete!();
    } else {
      print(
        'Deletion cancelled or onDelete is null. Result: $result, onDelete: ${widget.onDelete != null}',
      );
    }

    return result;
  }
}
