import 'package:exit_engine/exit_engine.dart';
import 'package:exitkompass_app/state/intake.dart';
import 'package:exitkompass_app/state/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exitkompass_app/main.dart';
import 'package:exitkompass_app/screens/abfindung_screen.dart';
import 'package:exitkompass_app/screens/finanzen_screen.dart';
import 'package:exitkompass_app/screens/start_hub_screen.dart';
import 'package:exitkompass_app/screens/wizard_screen.dart';

void main() {
  testWidgets('onboarding gates entry behind the disclaimer, then opens the hub',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: ExitKompassApp()));

    // The "Loslegen" button is disabled until the disclaimer is accepted.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loslegen'));
    await tester.pumpAndSettle();

    // Lands on the Start hub – the two journey cards are visible, wizard not forced.
    expect(find.byType(StartHubScreen), findsOneWidget);
    expect(find.text('Was steht dir zu?'), findsOneWidget);
    expect(find.text('Dein nächster Job'), findsOneWidget);
    expect(find.byType(WizardScreen), findsNothing);
  });

  testWidgets('Finanzen shows the scenarios and the wizard round-trips',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Seed complete example inputs + intake done, so the analysis is available
    // (with empty data the row would route to the input form first).
    await tester.pumpWidget(ProviderScope(
      overrides: [
        wizardProvider.overrideWith((ref) => WizardController(initial: WizardData())),
        intakeProvider
            .overrideWith((ref) => IntakeController(initial: const IntakeState(done: true))),
      ],
      child: const ExitKompassApp(),
    ));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loslegen'));
    await tester.pumpAndSettle();

    // Abfindung tab → open the scenario comparison via its row.
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Abfindung')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Netto-Szenarien & Fristen'));
    await tester.pumpAndSettle();
    expect(find.byType(FinanzenScreen), findsOneWidget);
    expect(find.text('Kündigung durch Arbeitgeber'), findsOneWidget);

    // Edit inputs via the wizard and finish → returns to the shell.
    await tester.tap(find.descendant(
        of: find.byType(FinanzenScreen), matching: find.byIcon(Icons.tune)));
    await tester.pumpAndSettle();
    expect(find.byType(WizardScreen), findsOneWidget);

    // The wizard is now a single scrollable form – finish via its button.
    await tester.ensureVisible(find.text('Szenarien vergleichen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Szenarien vergleichen'));
    await tester.pumpAndSettle();

    // The wizard closed and the pushed comparison was popped back to the shell,
    // now on the Abfindung tab.
    expect(find.byType(WizardScreen), findsNothing);
    expect(find.byType(AbfindungScreen), findsOneWidget);
  });

  test('default wizard data computes a full aggregate result', () {
    final result = WizardData().compute();
    expect(result.scenarios.keys.toSet(), ScenarioType.values.toSet());
    expect(result.baseline.cumulativeNetCents, greaterThan(0));
  });
}
