import 'package:exit_engine/exit_engine.dart';
import 'package:exitkompass_app/screens/liquidity_tab.dart';
import 'package:exitkompass_app/state/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WizardData.runwayFor', () {
    test('feeds the scenario cashflow, savings and expenses into M7', () {
      final data = WizardData(
        grossMonthEuro: 5000,
        monthlyExpensesEuro: 3000,
        savingsEuro: 20000,
      );
      final result = data.compute();
      final scenario = result.scenarios[ScenarioType.bleiben]!;

      final runway = data.runwayFor(ScenarioType.bleiben, aggregate: result);

      // Same length as the scenario cashflow, and the first month equals
      // savings + net[0] - expenses.
      expect(runway.balanceSeriesCents, hasLength(scenario.monthlyNetCents.length));
      expect(
        runway.balanceSeriesCents.first,
        20000 * 100 + scenario.monthlyNetCents.first - 3000 * 100,
      );
    });

    test('"Bleiben" (full salary) keeps the balance non-negative', () {
      final data = WizardData(grossMonthEuro: 5000, monthlyExpensesEuro: 2000, savingsEuro: 5000);
      final runway = data.runwayFor(ScenarioType.bleiben);
      expect(runway.survivesHorizon, isTrue);
    });

    test('high expenses with an income gap eventually deplete savings', () {
      final data = WizardData(
        grossMonthEuro: 3000,
        monthlyExpensesEuro: 4000, // more than the ALG can cover
        savingsEuro: 3000,
      );
      final runway = data.runwayFor(ScenarioType.eigenkuendigung);
      expect(runway.survivesHorizon, isFalse);
      expect(runway.firstNegativeMonth, isNotNull);
    });
  });

  testWidgets('LiquidityTab shows the runway headline and reacts to a scenario tap',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: LiquidityTab())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Reicht mein Geld bis zum neuen Job?'), findsOneWidget);
    // The four scenario chips are present.
    expect(find.text('Bleiben'), findsOneWidget);
    // Selecting "Bleiben" (full salary) yields a covered runway.
    await tester.tap(find.text('Bleiben'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tragen über die vollen'), findsOneWidget);
  });
}
