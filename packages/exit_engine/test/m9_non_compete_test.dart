import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

void main() {
  group('nonCompeteCompensation', () {
    test('minimum is half the last benefits per month', () {
      final r = nonCompeteCompensation(
        lastMonthlyBenefitsCents: 500000, // 5.000 €
        durationMonths: 12,
      );
      expect(r.minMonthlyCompensationCents, 250000); // 2.500 €
      expect(r.totalCompensationCents, 250000 * 12);
      expect(r.reducedByCredit, isFalse);
      expect(r.monthlyCompensationAfterCreditCents, 250000);
    });

    test('no credit while compensation + other income stays under 110 %', () {
      final r = nonCompeteCompensation(
        lastMonthlyBenefitsCents: 500000,
        durationMonths: 24,
        otherMonthlyIncomeCents: 300000, // 2.500 + 3.000 = 5.500 = 110 %
      );
      // Threshold is exactly 5.500 €; nothing above it → no credit.
      expect(r.creditThresholdMonthlyCents, 550000);
      expect(r.creditPerMonthCents, 0);
      expect(r.monthlyCompensationAfterCreditCents, 250000);
    });

    test('credits other income above the 110 % threshold (§ 74c)', () {
      final r = nonCompeteCompensation(
        lastMonthlyBenefitsCents: 500000,
        durationMonths: 12,
        otherMonthlyIncomeCents: 400000, // 2.500 + 4.000 = 6.500 > 5.500
      );
      // Excess 1.000 € is credited.
      expect(r.creditPerMonthCents, 100000);
      expect(r.monthlyCompensationAfterCreditCents, 150000);
      expect(r.totalAfterCreditCents, 150000 * 12);
      expect(r.reducedByCredit, isTrue);
    });

    test('relocation raises the threshold to 125 %', () {
      final r = nonCompeteCompensation(
        lastMonthlyBenefitsCents: 500000,
        durationMonths: 12,
        otherMonthlyIncomeCents: 400000,
        relocationForced: true,
      );
      // Threshold 6.250 €; sum 6.500 → credit only 250 €.
      expect(r.creditThresholdMonthlyCents, 625000);
      expect(r.creditPerMonthCents, 25000);
      expect(r.monthlyCompensationAfterCreditCents, 225000);
    });

    test('credit never pushes the compensation below zero', () {
      final r = nonCompeteCompensation(
        lastMonthlyBenefitsCents: 500000,
        durationMonths: 12,
        otherMonthlyIncomeCents: 900000, // very high other income
      );
      expect(r.monthlyCompensationAfterCreditCents, 0);
      expect(r.totalAfterCreditCents, 0);
    });

    test('flags a duration beyond the two-year maximum (§ 74a)', () {
      final r = nonCompeteCompensation(
        lastMonthlyBenefitsCents: 400000,
        durationMonths: 30,
      );
      expect(r.exceedsMaxDuration, isTrue);
      final ok = nonCompeteCompensation(
        lastMonthlyBenefitsCents: 400000,
        durationMonths: 24,
      );
      expect(ok.exceedsMaxDuration, isFalse);
    });
  });
}
