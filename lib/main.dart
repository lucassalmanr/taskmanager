import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AppWidget());
}

// ── Modelo ──────────────────────────────────────────────────────────────────

class Task {
  String id;
  String title;
  String description;
  DateTime? deadline; // null = sem prazo
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

  // Cor baseada na urgência do prazo
  Color get priorityColor {
    if (deadline == null) return const Color(0xFF7C4DFF); // roxo = sem prazo
    final diff = deadline!.difference(DateTime.now());
    if (diff.isNegative || diff.inHours < 6) return const Color(0xFFE53935);    // vermelho
    if (diff.inHours < 48) return const Color(0xFF1E88E5);                       // azul
    return const Color(0xFFE91E8C);                                              // pink
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

// ── App Root ─────────────────────────────────────────────────────────────────

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const TaskManagerScreen(),
    );
  }
}

// ── Tela Principal ────────────────────────────────────────────────────────────

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

  static const _kTasksKey = 'tasks_json';

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

  // ── Persistência ─────────────────────────────────────────────────────────

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _tasks.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_kTasksKey, jsonList);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_kTasksKey) ?? [];
    final loaded = jsonList.map((s) => Task.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
    setState(() => _tasks.addAll(loaded));
  }

  // ── Lógica ────────────────────────────────────────────────────────────────

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
              _buildTextField(titleCtrl, 'Título da tarefa', false),
              const SizedBox(height: 12),
              _buildTextField(descCtrl, 'Descrição (Opcional)', false),
              const SizedBox(height: 12),
              _deadlinePickerButton(
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

  // ── Seletor de Prazo ──────────────────────────────────────────────────────

  Future<void> _pickDeadline(Function(DateTime?) onPicked) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Horário (opcional — toque em Cancel para pular)',
    );

    if (time != null) {
      onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
    } else {
      onPicked(DateTime(date.year, date.month, date.day, 23, 59));
    }
  }

  Widget _deadlinePickerButton({
    required DateTime? deadline,
    required Function(DateTime?) onChanged,
  }) {
    return GestureDetector(
      onTap: () => _pickDeadline(onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                deadline == null
                    ? 'Digite seu prazo'
                    : '${deadline.day.toString().padLeft(2, '0')}/${deadline.month.toString().padLeft(2, '0')}/${deadline.year}  '
                        '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: deadline == null ? Colors.grey.shade600 : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            if (deadline != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  // ── Campo de texto padronizado ────────────────────────────────────────────

  Widget _buildTextField(TextEditingController ctrl, String label, bool isDesc) {
    return TextField(
      controller: ctrl,
      maxLines: isDesc ? 3 : 1,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFF0EEFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  // ── Detalhes da Tarefa ───────────────────────────────────────────────────

  void _showDetails(Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar', style: TextStyle(color: Colors.white70)),
          ),
          if (!task.isCompleted)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: task.priorityColor,
              ),
              onPressed: () {
                _completeTask(task);
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.check),
              label: const Text('Concluir'),
            ),
        ],
      ),
    );
  }

  // ── Cards ────────────────────────────────────────────────────────────────

  Widget _buildTaskCard(Task task) {
    return GestureDetector(
      onTap: () => _showDetails(task),
      onLongPress: () => _editTask(task),
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: task.priorityColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: task.priorityColor.withValues(alpha: 0.45), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _deleteTask(task),
                  child: const Icon(Icons.close, color: Colors.white60, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white70, size: 13),
                const SizedBox(width: 4),
                Text(task.deadlineLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activeTasks = _tasks.where((t) => !t.isCompleted).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
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
                  _buildTextField(_titleController, 'Digite sua tarefa', false),
                  const SizedBox(height: 12),
                  _buildTextField(_descController, 'Digite sua Descrição', true),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (ctx, setLocal) => _deadlinePickerButton(
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

            // ── Grade de Tarefas ──────────────────────────────────────────
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
                      itemBuilder: (ctx, i) => _buildTaskCard(activeTasks[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
