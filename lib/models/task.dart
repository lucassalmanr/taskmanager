import 'package:flutter/material.dart';

class Task {
  String id;
  String title;
  String description;
  DateTime? deadline;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.deadline,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'deadline': deadline?.toIso8601String(),
    'isCompleted': isCompleted,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );

  Color get priorityColor {
    if (deadline == null) return const Color(0xFF7C4DFF);
    final diff = deadline!.difference(DateTime.now());
    if (diff.isNegative || diff.inHours < 6) return const Color(0xFFE53935);
    if (diff.inHours < 48) return const Color(0xFF1E88E5);
    return const Color(0xFFE91E8C);
  }

  String get deadlineLabel {
    if (deadline == null) return 'Sem prazo';
    final diff = deadline!.difference(DateTime.now());
    if (diff.isNegative) return 'Atrasada!';
    if (diff.inMinutes < 60) return 'Faltam ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Faltam ${diff.inHours}h';
    return 'Faltam ${diff.inDays}d';
  }
}
