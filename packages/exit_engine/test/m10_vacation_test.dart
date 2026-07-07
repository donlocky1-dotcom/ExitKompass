import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

void main() {
  group('vacationCompensation', () {
    test('daily value follows the 13-week formula (5-day week)', () {
      final v = vacationCompensation(
        monthlyGrossCents: 500000, // 5.000 €
        remainingDays: 10,
      );
      // 5000 × 3 / 65 = 230,77 €/day.
      expect(v.dailyValueCents, 23077);
      expect(v.totalCents, 230770);
      expect(v.workDaysPerWeek, 5);
    });

    test('fewer working days per week raise the daily value', () {
      final five = vacationCompensation(monthlyGrossCents: 500000, remainingDays: 1);
      final four = vacationCompensation(
          monthlyGrossCents: 500000, remainingDays: 1, workDaysPerWeek: 4);
      expect(four.dailyValueCents, greaterThan(five.dailyValueCents));
    });

    test('zero open days → zero compensation', () {
      final v = vacationCompensation(monthlyGrossCents: 500000, remainingDays: 0);
      expect(v.totalCents, 0);
    });
  });

  group('proRataVacationDays', () {
    test('full year returns the full entitlement', () {
      expect(proRataVacationDays(fullYearDays: 30, monthsEmployed: 12), 30);
    });

    test('rounds fractions of at least half a day up (§ 5 Abs. 2)', () {
      // 30 × 7 / 12 = 17.5 → 18.
      expect(proRataVacationDays(fullYearDays: 30, monthsEmployed: 7), 18);
      // 24 × 5 / 12 = 10.0 → 10.
      expect(proRataVacationDays(fullYearDays: 24, monthsEmployed: 5), 10);
    });

    test('clamps months to the 0..12 range', () {
      expect(proRataVacationDays(fullYearDays: 30, monthsEmployed: 20), 30);
      expect(proRataVacationDays(fullYearDays: 30, monthsEmployed: 0), 0);
    });
  });
}
