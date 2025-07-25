import 'package:flutter/material.dart';

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime date;
  final Priority priority;
  final Category category;
  final bool isCompleted;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.priority,
    required this.category,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'priority': priority.index,
      'category': category.index,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      priority: Priority.values[map['priority']],
      category: Category.values[map['category']],
      isCompleted: map['isCompleted'] == 1,
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    Priority? priority,
    Category? category,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

enum Priority { low, medium, high }

enum Category { work, personal, study, health, shopping }

extension PriorityExtension on Priority {
  String get name {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case Priority.low:
        return Icons.keyboard_arrow_down;
      case Priority.medium:
        return Icons.remove;
      case Priority.high:
        return Icons.keyboard_arrow_up;
    }
  }
}

extension CategoryExtension on Category {
  String get name {
    switch (this) {
      case Category.work:
        return 'Work';
      case Category.personal:
        return 'Personal';
      case Category.study:
        return 'Study';
      case Category.health:
        return 'Health';
      case Category.shopping:
        return 'Shopping';
    }
  }

  Color get color {
    switch (this) {
      case Category.work:
        return Colors.blue;
      case Category.personal:
        return Colors.purple;
      case Category.study:
        return Colors.teal;
      case Category.health:
        return Colors.pink;
      case Category.shopping:
        return Colors.amber;
    }
  }

  IconData get icon {
    switch (this) {
      case Category.work:
        return Icons.work;
      case Category.personal:
        return Icons.person;
      case Category.study:
        return Icons.school;
      case Category.health:
        return Icons.favorite;
      case Category.shopping:
        return Icons.shopping_cart;
    }
  }
}
