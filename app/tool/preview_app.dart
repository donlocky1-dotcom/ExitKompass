// Preview entrypoint that runs the full app UI without the Drift database.
// Persistence uses shared_preferences (IndexedDB on the web) so all inputs
// – wizard, intake, CV/job ad and the coach conversations – survive a reload.
// Build:
//   flutter build web -t tool/preview_app.dart --no-web-resources-cdn
import 'package:exitkompass_app/coach/coach_engine.dart';
import 'package:exitkompass_app/main.dart';
import 'package:exitkompass_app/state/application_docs.dart';
import 'package:exitkompass_app/state/coach_session.dart';
import 'package:exitkompass_app/state/intake.dart';
import 'package:exitkompass_app/state/prefs_stores.dart';
import 'package:exitkompass_app/state/wizard.dart';
import 'package:exitkompass_app/state/workbook.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads persisted state, but never lets a slow or stuck storage backend block
/// the first frame. On iOS Safari the IndexedDB-backed store can hang or be
/// unavailable (private mode, storage pressure); if a load does not resolve in
/// time we boot with defaults instead of showing a blank page forever.
Future<T> _load<T>(Future<T> Function() read, T fallback) async {
  try {
    return await read().timeout(const Duration(seconds: 6));
  } catch (_) {
    return fallback;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run the loads concurrently so the slowest one bounds startup, not the sum.
  final results = await Future.wait<Object?>([
    _load<WizardData?>(WizardPrefsStore.load, null),
    _load<Map<String, String>>(WorkbookPrefsStore.load, const {}),
    _load<ApplicationDocs>(loadApplicationDocs, const ApplicationDocs()),
    _load<IntakeState>(loadIntake, const IntakeState()),
    _load<Map<CoachMode, CoachSession>>(loadCoachSessions, const {}),
  ]);

  final wizardData = results[0] as WizardData?;
  final workbookAnswers = results[1] as Map<String, String>;
  final docs = results[2] as ApplicationDocs;
  final intake = results[3] as IntakeState;
  final coachSessions = results[4] as Map<CoachMode, CoachSession>;

  runApp(
    ProviderScope(
      overrides: [
        wizardProvider.overrideWith(
          (ref) => WizardController(
              repository: WizardPrefsStore(), initial: wizardData),
        ),
        workbookProvider.overrideWith(
          (ref) => WorkbookController(
              repository: WorkbookPrefsStore(), initial: workbookAnswers),
        ),
        applicationDocsProvider.overrideWith(
          (ref) => ApplicationDocsController(initial: docs),
        ),
        intakeProvider.overrideWith(
          (ref) => IntakeController(initial: intake),
        ),
        coachSessionProvider.overrideWith(
          (ref) => CoachSessionController(initial: coachSessions),
        ),
      ],
      child: const ExitKompassApp(),
    ),
  );
}
