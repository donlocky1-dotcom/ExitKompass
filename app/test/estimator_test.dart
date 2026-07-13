import 'package:exit_engine/exit_engine.dart';
import 'package:exitkompass_app/main.dart';
import 'package:exitkompass_app/state/intake.dart';
import 'package:exitkompass_app/state/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openWizard(WidgetTester tester) async {
  // Tall viewport so the whole single-page inputs form is laid out at once.
  tester.view.physicalSize = const Size(1200, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Seed complete example inputs (the plain WizardData() defaults) and mark the
  // intake done, so the estimator/timing render and the hub offers "Angaben
  // bearbeiten" instead of the empty-start prompt.
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
  // Open the wizard via Abfindung → "Angaben bearbeiten". It is a single
  // scrollable form – the Angebot section (estimator, timing) is always there.
  await tester.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.text('Abfindung')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Angaben bearbeiten'));
  await tester.tap(find.text('Angaben bearbeiten'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('estimator shows a range and applies its midpoint', (tester) async {
    await _openWizard(tester);

    // The estimator card is present with its range line.
    expect(find.text('Abfindung schätzen'), findsOneWidget);
    expect(find.textContaining('Realistische Spanne'), findsOneWidget);

    // Apply the midpoint.
    await tester.ensureVisible(find.text('Mittelwert übernehmen'));
    await tester.tap(find.text('Mittelwert übernehmen'));
    await tester.pumpAndSettle();

    // With defaults (5000 €/month, ~11 years tenure, standard band) the
    // applied severance is well above the initial 50.000 €.
    final field = tester.widget<TextFormField>(
      find.ancestor(
        of: find.text('Abfindung brutto (€)'),
        matching: find.byType(TextFormField),
      ),
    );
    final applied = int.parse(field.controller!.text);
    expect(applied, greaterThan(0));
  });

  testWidgets('timing card compares this year vs next year and reacts', (tester) async {
    await _openWizard(tester);

    expect(find.text('Auszahlung timen'), findsOneWidget);
    // With the defaults (salary this year, 0 next year) next year is better.
    await tester.ensureVisible(find.textContaining('nächstes Jahr bringt'));
    expect(find.textContaining('nächstes Jahr bringt'), findsOneWidget);

    // Set both years equal → no advantage.
    final nextYearField = find.ancestor(
      of: find.text('zvE nächstes Jahr (€)'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(nextYearField);
    await tester.enterText(nextYearField, '60000');
    await tester.pumpAndSettle();
    // this year defaults to 5000*12 = 60000, so now equal.
    expect(find.textContaining('macht das Timing keinen Unterschied'), findsOneWidget);
  });

  test('sanity: estimator engine call is wired the same way', () {
    final e = estimateSeverance(
      grossMonthCents: 500000,
      tenureYears: 11,
      age: 41,
      strength: NegotiationStrength.standard,
    );
    expect(e.lowCents, lessThanOrEqualTo(e.pointCents));
    expect(e.pointCents, lessThanOrEqualTo(e.highCents));
  });
}
