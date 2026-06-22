import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/deadline_picker.dart';
import '../widgets/task_card.dart';
import '../widgets/task_detail_dialog.dart';

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final List<Task> _tasks = [];

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDeadline;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveTasks() => StorageService.saveTasks(_tasks);

  Future<void> _loadTasks() async {
    final loaded = await StorageService.loadTasks();
    setState(() => _tasks.addAll(loaded));
  }

  void _addTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _tasks.add(Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: _descController.text.trim(),
        deadline: _selectedDeadline,
      ));
      _titleController.clear();
      _descController.clear();
      _selectedDeadline = null;
    });

    _updateWidget();
    _saveTasks();
  }

  void _completeTask(Task task) {
    setState(() => task.isCompleted = true);
    _updateWidget();
    _saveTasks();
  }

  void _deleteTask(Task task) {
    setState(() => _tasks.removeWhere((t) => t.id == task.id));
    _updateWidget();
    _saveTasks();
  }

  void _editTask(Task task) {
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description);
    DateTime? editDeadline = task.deadline;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Editar Tarefa', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: titleCtrl, label: 'Título da tarefa'),
              const SizedBox(height: 12),
              CustomTextField(controller: descCtrl, label: 'Descrição (Opcional)', isDescription: true),
              const SizedBox(height: 12),
              DeadlinePicker(
                deadline: editDeadline,
                onChanged: (dt) => setDialogState(() => editDeadline = dt),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  task.title = titleCtrl.text.trim().isEmpty ? task.title : titleCtrl.text.trim();
                  task.description = descCtrl.text.trim();
                  task.deadline = editDeadline;
                });
                _updateWidget();
                _saveTasks();
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateWidget() async {
    final pending = _tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) {
        if (a.deadline == null && b.deadline == null) return 0;
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      });

    String text = pending.isEmpty
        ? 'Tudo em dia! ✨'
        : pending.map((t) => '• ${t.title}  (${t.deadlineLabel})').join('\n');

    await HomeWidget.saveWidgetData<String>('widget_tasks_string', text);
    await HomeWidget.updateWidget(name: 'AppWidgetProvider');
  }

  @override
  Widget build(BuildContext context) {
    final activeTasks = _tasks.where((t) => !t.isCompleted).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Task Manager',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(controller: _titleController, label: 'Digite sua tarefa'),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _descController, label: 'Digite sua Descrição', isDescription: true),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (ctx, setLocal) => DeadlinePicker(
                      deadline: _selectedDeadline,
                      onChanged: (dt) => setState(() => _selectedDeadline = dt),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _addTask,
                      child: const Text('Add Tarefa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: activeTasks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.task_alt, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Nenhuma tarefa!', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.55,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0,
                      ),
                      itemCount: activeTasks.length,
                      itemBuilder: (ctx, i) => TaskCard(
                        task: activeTasks[i],
                        onTap: () => _showDetails(activeTasks[i]),
                        onLongPress: () => _onLongPress(activeTasks[i]),
                        onDelete: () => _deleteTask(activeTasks[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(Task task) {
    TaskDetailDialog.show(context, task, () => _completeTask(task));
  }

  void _onLongPress(Task task) {
    _editTask(task);
  }
}
