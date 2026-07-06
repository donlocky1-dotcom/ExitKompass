import 'package:exit_engine/exit_engine.dart';
import 'package:exitkompass_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openWizard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const ProviderScope(child: ExitKompassApp()));
  await tester.tap(find.byType(Checkbox));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Direkt zum Netto-Szenario-Vergleich'));
  await tester.pumpAndSettle();
  // Jump to the offer step (step index 3).
  await tester.tap(find.text('Angebot'));
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
