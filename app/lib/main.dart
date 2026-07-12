import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/app_database.dart';
import 'data/wizard_repository.dart';
import 'data/workbook_repository.dart';
import 'screens/onboarding_screen.dart';
import 'state/application_docs.dart';
import 'state/coach_session.dart';
import 'state/intake.dart';
import 'state/wizard.dart';
import 'state/workbook.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local, on-device persistence (no backend/account/cloud, per CLAUDE.md).
  final db = AppDatabase();
  final repository = WizardRepository(db);
  final saved = await repository.load();
  final workbookRepo = WorkbookRepository(db);
  final savedAnswers = await workbookRepo.loadAll();
  final coachSessions = await loadCoachSessions();
  final docs = await loadApplicationDocs();
  final intake = await loadIntake();

  runApp(
    ProviderScope(
      overrides: [
        wizardProvider.overrideWith(
          (ref) => WizardController(repository: repository, initial: saved),
        ),
        workbookProvider.overrideWith(
          (ref) => WorkbookController(repository: workbookRepo, initial: savedAnswers),
        ),
        coachSessionProvider.overrideWith(
          (ref) => CoachSessionController(initial: coachSessions),
        ),
        applicationDocsProvider.overrideWith(
          (ref) => ApplicationDocsController(initial: docs),
        ),
        intakeProvider.overrideWith(
          (ref) => IntakeController(initial: intake),
        ),
      ],
      child: const ExitKompassApp(),
    ),
  );
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
        // Bundled fonts: the web (CanvasKit) build must not depend on fetching
        // Roboto from fonts.gstatic.com, or blocked networks see a blank page.
        // Roboto ships in-app; DejaVuSans covers any missing glyphs.
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['DejaVuSans'],
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const OnboardingScreen(),
    );
  }
}
