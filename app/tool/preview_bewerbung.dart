// Preview entrypoint for visual verification of the Bewerbungstraining
// screen. Build: flutter build web -t tool/preview_bewerbung.dart --no-web-resources-cdn
import 'package:exitkompass_app/screens/bewerbung_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(ProviderScope(
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00696E)),
        useMaterial3: true,
      ),
      home: const BewerbungScreen(),
    ),
  ));
}
