import 'package:exit_engine/exit_engine.dart';
import 'package:exitkompass_app/state/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exitkompass_app/main.dart';
import 'package:exitkompass_app/screens/wizard_screen.dart';
import 'package:exitkompass_app/screens/home_shell.dart';

void main() {
  testWidgets('onboarding gates the wizard behind the disclaimer checkbox',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ExitKompassApp()));

    // Continue button is disabled until the disclaimer is accepted.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    final enabled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(enabled.onPressed, isNotNull);

    await tester.tap(find.text('Direkt zum Netto-Szenario-Vergleich'));
    await tester.pumpAndSettle();

    expect(find.byType(WizardScreen), findsOneWidget);
    expect(find.text('Situation'), findsWidgets);
  });

  testWidgets('wizard reaches the result screen and shows all four scenarios',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ExitKompassApp()));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Direkt zum Netto-Szenario-Vergleich'));
    await tester.pumpAndSettle();

    // Advance through the four steps with the default inputs. The
    // continue button can sit below the fold in the test viewport, so
    // scroll it into view first.
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.text('Weiter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Szenarien vergleichen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Szenarien vergleichen'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Bleiben'), findsWidgets);
    expect(find.text('Kündigung durch Arbeitgeber'), findsOneWidget);

    // The Fristen and Ratgeber tabs are reachable.
    await tester.tap(find.text('Fristen'));
    await tester.pumpAndSettle();
    expect(find.text('Deine Fristen'), findsOneWidget);

    await tester.tap(find.text('Ratgeber'));
    await tester.pumpAndSettle();
    expect(find.text('Verhandlung'), findsWidgets);
  });

  test('default wizard data computes a full aggregate result', () {
    final result = WizardData().compute();
    expect(result.scenarios.keys.toSet(), ScenarioType.values.toSet());
    expect(result.baseline.cumulativeNetCents, greaterThan(0));
  });
}
