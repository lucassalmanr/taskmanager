import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskDetailDialog extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;

  const TaskDetailDialog({
    super.key,
    required this.task,
    required this.onComplete,
  });

  static Future<void> show(BuildContext context, Task task, VoidCallback onComplete) {
    return showDialog(
      context: context,
      builder: (_) => TaskDetailDialog(task: task, onComplete: onComplete),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: task.priorityColor,
      title: Text(
        task.title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.description.isNotEmpty)
            Text(task.description, style: const TextStyle(color: Colors.white, fontSize: 15)),
          if (task.description.isEmpty)
            const Text('Sem descrição.', style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(task.deadlineLabel, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar', style: TextStyle(color: Colors.white70)),
        ),
        if (!task.isCompleted)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: task.priorityColor,
            ),
            onPressed: () {
              onComplete();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('Concluir'),
          ),
      ],
    );
  }
}
