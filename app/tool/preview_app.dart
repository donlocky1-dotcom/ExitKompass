// Preview entrypoint that runs the full app UI without the Drift database
// (in-memory state via the default providers), so it builds and runs on the
// web for screenshots. Build:
//   flutter build web -t tool/preview_app.dart --no-web-resources-cdn
import 'package:exitkompass_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: ExitKompassApp()));
}
