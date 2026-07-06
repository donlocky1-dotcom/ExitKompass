import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

void main() {
  group('computeRunway', () {
    test('savings grow when net income exceeds expenses', () {
      final plan = computeRunway(
        monthlyNetCents: List.filled(6, 300000), // 3000 €/month in
        startingSavingsCents: 1000000, // 10.000 €
        monthlyExpensesCents: 250000, // 2500 €/month out
      );
      // +500 €/month → 10.000, 10.500 … 13.000
      expect(plan.balanceSeriesCents.first, 1050000);
      expect(plan.endBalanceCents, 1300000);
      expect(plan.survivesHorizon, isTrue);
      expect(plan.firstNegativeMonth, isNull);
      expect(plan.monthsCovered, 6);
    });

    test('finds the month the money runs out during an income gap', () {
      // No income at all, 2000 € expenses, 5000 € savings.
      final plan = computeRunway(
        monthlyNetCents: List.filled(6, 0),
        startingSavingsCents: 500000,
        monthlyExpensesCents: 200000,
      );
      // 5000 → 3000 → 1000 → -1000 (month index 2) …
      expect(plan.balanceSeriesCents, [300000, 100000, -100000, -300000, -500000, -700000]);
      expect(plan.firstNegativeMonth, 2);
      expect(plan.survivesHorizon, isFalse);
      expect(plan.monthsCovered, 2);
      expect(plan.minBalanceCents, -700000);
      expect(plan.minBalanceMonth, 5);
    });

    test('tracks the low point even when the balance recovers', () {
      // Gap first (drains), then salary resumes (recovers).
      final plan = computeRunway(
        monthlyNetCents: [0, 0, 400000, 400000],
        startingSavingsCents: 300000,
        monthlyExpensesCents: 200000,
      );
      // 100.000, -100.000 (low), 100.000, 300.000
      expect(plan.balanceSeriesCents, [100000, -100000, 100000, 300000]);
      expect(plan.minBalanceCents, -100000);
      expect(plan.minBalanceMonth, 1);
      expect(plan.firstNegativeMonth, 1);
      expect(plan.endBalanceCents, 300000);
    });

    test('an empty horizon returns the starting savings', () {
      final plan = computeRunway(
        monthlyNetCents: const [],
        startingSavingsCents: 500000,
        monthlyExpensesCents: 200000,
      );
      expect(plan.balanceSeriesCents, isEmpty);
      expect(plan.endBalanceCents, 500000);
      expect(plan.minBalanceCents, 500000);
      expect(plan.survivesHorizon, isTrue);
      expect(plan.monthsCovered, 0);
    });
  });
}
