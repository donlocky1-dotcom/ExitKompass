// Preview entrypoint that runs the full app UI without the Drift database.
// Persistence uses shared_preferences (localStorage on the web) so all inputs
// – wizard, intake, CV/job ad and the coach conversations – survive a reload.
// Build:
//   flutter build web -t tool/preview_app.dart --no-web-resources-cdn
import 'package:exitkompass_app/main.dart';
import 'package:exitkompass_app/state/application_docs.dart';
import 'package:exitkompass_app/state/coach_session.dart';
import 'package:exitkompass_app/state/intake.dart';
import 'package:exitkompass_app/state/prefs_stores.dart';
import 'package:exitkompass_app/state/wizard.dart';
import 'package:exitkompass_app/state/workbook.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final wizardData = await WizardPrefsStore.load();
  final workbookAnswers = await WorkbookPrefsStore.load();
  final docs = await loadApplicationDocs();
  final intake = await loadIntake();
  final coachSessions = await loadCoachSessions();

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
