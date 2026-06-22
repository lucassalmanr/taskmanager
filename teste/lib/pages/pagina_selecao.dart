import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pagina_inicial.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  int _hojeCount = 0;
  int _semanaCount = 0;
  int _algumDiaCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // 1. Executa a migração caso existam dados antigos no SharedPreferences
    await _migrateLegacyData();
    // 2. Carrega as contagens
    await _loadCounts();
  }

  Future<void> _migrateLegacyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (kIsWeb) {
        if (prefs.containsKey('tasks_json') && !prefs.containsKey('tasks_hoje')) {
          final jsonList = prefs.getStringList('tasks_json') ?? [];
          await prefs.setStringList('tasks_hoje', jsonList);
          await prefs.remove('tasks_json');
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final hojeFile = File('${dir.path}/hoje.json');
        
        // Só migra se hoje.json não existir e existirem tarefas antigas
        if (!await hojeFile.exists() && prefs.containsKey('tasks_json')) {
          final jsonList = prefs.getStringList('tasks_json') ?? [];
          if (jsonList.isNotEmpty) {
            final tasks = jsonList.map((s) => jsonDecode(s)).toList();
            await hojeFile.writeAsString(jsonEncode(tasks));
          }
          await prefs.remove('tasks_json');
        }
      }
    } catch (e) {
      debugPrint('Erro na migração: $e');
    }
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);
    final hoje = await _getPendingCount('Para hoje');
    final semana = await _getPendingCount('Para a semana');
    final algumDia = await _getPendingCount('Para algum dia');
    
    if (mounted) {
      setState(() {
        _hojeCount = hoje;
        _semanaCount = semana;
        _algumDiaCount = algumDia;
        _isLoading = false;
      });
    }
  }

  Future<int> _getPendingCount(String category) async {
    try {
      List<dynamic> jsonList = [];
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        String key = _getPrefsKey(category);
        final list = prefs.getStringList(key) ?? [];
        jsonList = list.map((s) => jsonDecode(s)).toList();
      } else {
        final dir = await getApplicationDocumentsDirectory();
        String filename;
        if (category == 'Para hoje') {
          filename = 'hoje.json';
        } else if (category == 'Para a semana') {
          filename = 'semana.json';
        } else {
          filename = 'algum_dia.json';
        }
        final file = File('${dir.path}/$filename');
        if (!await file.exists()) return 0;
        
        final contents = await file.readAsString();
        jsonList = jsonDecode(contents);
      }
      
      int count = 0;
      for (var item in jsonList) {
        if (item is Map<String, dynamic>) {
          final isCompleted = item['isCompleted'] as bool? ?? false;
          if (!isCompleted) {
            count++;
          }
        }
      }
      return count;
    } catch (e) {
      debugPrint('Erro ao obter contagem para $category: $e');
      return 0;
    }
  }

  String _getPrefsKey(String category) {
    if (category == 'Para hoje') return 'tasks_hoje';
    if (category == 'Para a semana') return 'tasks_semana';
    return 'tasks_algum_dia';
  }

  void _navigateToCategory(String category) async {
    // Navega para a tela de tarefas e aguarda o retorno para atualizar as contagens
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskManagerScreen(category: category),
      ),
    );
    _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    // Cabeçalho da tela
                    const Text(
                      'Task Manager',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Organize seu dia, planeje seu futuro.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Cards de Seleção
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          CategoryCard(
                            title: 'Para hoje',
                            subtitle: _hojeCount == 1 ? '1 tarefa pendente' : '$_hojeCount tarefas pendentes',
                            icon: Icons.today_rounded,
                            pendingCount: _hojeCount,
                            gradientColors: const [
                              Color(0xFFEE0979),
                              Color(0xFFFF6A00),
                            ],
                            onTap: () => _navigateToCategory('Para hoje'),
                          ),
                          CategoryCard(
                            title: 'Para a semana',
                            subtitle: _semanaCount == 1 ? '1 tarefa pendente' : '$_semanaCount tarefas pendentes',
                            icon: Icons.calendar_view_week_rounded,
                            pendingCount: _semanaCount,
                            gradientColors: const [
                              Color(0xFF00C6FF),
                              Color(0xFF0072FF),
                            ],
                            onTap: () => _navigateToCategory('Para a semana'),
                          ),
                          CategoryCard(
                            title: 'Para algum dia',
                            subtitle: _algumDiaCount == 1 ? '1 tarefa pendente' : '$_algumDiaCount tarefas pendentes',
                            icon: Icons.wb_cloudy_outlined,
                            pendingCount: _algumDiaCount,
                            gradientColors: const [
                              Color(0xFF7F00FF),
                              Color(0xFFE100FF),
                            ],
                            onTap: () => _navigateToCategory('Para algum dia'),
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
}

class CategoryCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final int pendingCount;

  const CategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    required this.pendingCount,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          height: 120,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icone com círculo translúcido
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Conteúdo textual
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
