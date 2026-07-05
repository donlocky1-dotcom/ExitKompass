import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/onboarding_screen.dart';

void main() {
  runApp(const ProviderScope(child: ExitKompassApp()));
}

class ExitKompassApp extends StatelessWidget {
  const ExitKompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00696E),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'ExitKompass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const OnboardingScreen(),
    );
  }
}
