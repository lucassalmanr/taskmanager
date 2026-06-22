import 'package:flutter/material.dart';
import 'pages/pagina_selecao.dart';

void main() {
  runApp(const AppWidget());
}

// ── Modelo ──────────────────────────────────────────────────────────────────



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
      home: const CategorySelectionScreen(),
    );
  }
}
