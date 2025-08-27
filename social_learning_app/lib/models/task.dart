import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { pending, inProgress, completed }

class Task {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String assignedTo;
  final int priority; // 1-5, where 5 is highest priority
  final String? userId; // Firebase user ID

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.status = TaskStatus.pending,
    required this.dueDate,
    DateTime? createdAt,
    this.updatedAt,
    this.assignedTo = '',
    this.priority = 3,
    this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == 'TaskStatus.${json['status']}',
        orElse: () => TaskStatus.pending,
      ),
      dueDate: json['dueDate'] is String
          ? DateTime.parse(json['dueDate'])
          : (json['dueDate'] as Timestamp).toDate(),
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is String
                ? DateTime.parse(json['updatedAt'])
                : (json['updatedAt'] as Timestamp).toDate())
          : null,
      assignedTo: json['assignedTo'] ?? '',
      priority: json['priority'] ?? 3,
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'assignedTo': assignedTo,
      'priority': priority,
      'userId': userId,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedTo,
    int? priority,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
    );
  }

  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) && status != TaskStatus.completed;

  String get statusText {
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

  Color get statusColor {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  // Get priority text
  String get priorityText {
    switch (priority) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Very High';
      default:
        return 'Medium';
    }
  }

  // Get priority color
  Color get priorityColor {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Check if task is due soon (within 3 days)
  bool get isDueSoon {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference >= 0 && difference <= 3 && status != TaskStatus.completed;
  }

  // Check if task is due today
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, priority: $priority)';
  }
}
