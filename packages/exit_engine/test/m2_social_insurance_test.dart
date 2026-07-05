import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

int eur(int euro) => euro * 100;

void main() {
  group('M2 – social insurance: standard cases', () {
    test('60,000 € (below both ceilings), childless, age 30', () {
      final sv = employeeSocialContributions(grossYearCents: eur(60000), age: 30);
      expect(sv.healthCents, eur(5250), reason: 'health: (14.6/2 + 2.9/2) % = 8.75 %');
      expect(sv.careCents, eur(1440), reason: 'care: 1.8 % + 0.6 % childless surcharge');
      expect(sv.pensionCents, eur(5580), reason: 'pension: 9.3 %');
      expect(sv.unempCents, eur(780), reason: 'unemployment: 1.3 %');
      expect(sv.totalCents, eur(13050));
    });

    test('half-up rounding to full cents', () {
      // 33,333 € * 8.75 % = 2,916.6375 € -> 2,916.64 €
      final sv = employeeSocialContributions(grossYearCents: eur(33333), age: 30);
      expect(sv.healthCents, 291664);
    });
  });

  group('M2 – capping at the contribution assessment ceilings', () {
    test('80,000 €: above the health/care ceiling (69,750), below pension/unemp', () {
      final sv = employeeSocialContributions(grossYearCents: eur(80000), age: 40);
      expect(sv.healthCents, 610313, reason: 'health capped: 69,750 * 8.75 % = 6,103.125');
      expect(sv.careCents, eur(1674), reason: 'care capped: 69,750 * 2.4 %');
      expect(sv.pensionCents, eur(7440), reason: 'pension uncapped: 80,000 * 9.3 %');
      expect(sv.unempCents, eur(1040), reason: 'unemployment uncapped: 80,000 * 1.3 %');
    });

    test('130,000 €: above both ceilings', () {
      final sv = employeeSocialContributions(grossYearCents: eur(130000), age: 40);
      expect(sv.healthCents, 610313);
      expect(sv.careCents, eur(1674));
      expect(sv.pensionCents, 943020, reason: 'pension capped: 101,400 * 9.3 % = 9,430.20');
      expect(sv.unempCents, 131820, reason: 'unemployment capped: 101,400 * 1.3 % = 1,318.20');
    });

    test('contributions stay constant above both ceilings', () {
      final a = employeeSocialContributions(grossYearCents: eur(130000), age: 40);
      final b = employeeSocialContributions(grossYearCents: eur(500000), age: 40);
      expect(a.totalCents, b.totalCents);
    });

    test('exactly at a ceiling: identical to any higher gross (health/care)', () {
      final atCeiling = employeeSocialContributions(grossYearCents: eur(69750), age: 40);
      final above = employeeSocialContributions(grossYearCents: eur(69751), age: 40);
      expect(atCeiling.healthCents, above.healthCents);
      expect(atCeiling.careCents, above.careCents);
      expect(atCeiling.pensionCents, lessThan(above.pensionCents));
    });
  });

  group('M2 – care insurance: child logic (§ 55 SGB XI)', () {
    double careRate(
            {required int age,
            int children = 0,
            int childrenU25 = 0,
            Bundesland state = Bundesland.nordrheinWestfalen}) =>
        employeeSocialContributions(
          grossYearCents: eur(50000),
          age: age,
          totalChildren: children,
          childrenUnder25: childrenU25,
          state: state,
        ).careRateEmployee;

    test('childless surcharge only from age 23', () {
      expect(careRate(age: 22), closeTo(0.018, 1e-12));
      expect(careRate(age: 23), closeTo(0.024, 1e-12));
    });

    test('1 child: no surcharge, no discount', () {
      expect(careRate(age: 40, children: 1, childrenU25: 1), closeTo(0.018, 1e-12));
    });

    test('2 children under 25: one discount of 0.25 pp', () {
      expect(careRate(age: 40, children: 2, childrenU25: 2), closeTo(0.0155, 1e-12));
    });

    test('discounts are capped at 4 (children 2–5)', () {
      expect(careRate(age: 45, children: 6, childrenU25: 6),
          closeTo(0.018 - 4 * 0.0025, 1e-12));
    });

    test('grown-up children do not count for the discount but prevent the surcharge',
        () {
      expect(careRate(age: 55, children: 2, childrenU25: 0), closeTo(0.018, 1e-12));
    });

    test('Saxony: employee share 0.5 pp higher', () {
      expect(careRate(age: 40, children: 1, childrenU25: 1, state: Bundesland.sachsen),
          closeTo(0.023, 1e-12));
    });
  });

  group('M2 – additional health insurance rate', () {
    test('fund-specific additional rate overrides the average', () {
      final cheap = employeeSocialContributions(
          grossYearCents: eur(60000), age: 30, healthAdditionalRate: 0.019);
      // (14.6/2 + 1.9/2) % = 8.25 %
      expect(cheap.healthCents, eur(4950));
    });
  });

  group('net income estimate (M1 + M2)', () {
    test('60,000 €, class I, childless: net = gross − taxes − social insurance', () {
      final net = annualNetIncome(
        grossYearCents: eur(60000),
        taxClass: TaxClass.i,
        age: 30,
      );
      // wage tax 9,328 (M1 test) + social insurance 13,050 (M2 test)
      expect(net.netYearCents, eur(60000 - 9328 - 13050));
      expect(net.netMonthCents, (net.netYearCents / 12).round());
    });

    test('a church member has less net income', () {
      NetIncomeResult withChurch(bool member) => annualNetIncome(
            grossYearCents: eur(60000),
            taxClass: TaxClass.i,
            age: 30,
            churchMember: member,
            state: Bundesland.bayern,
          );
      expect(withChurch(true).netYearCents, lessThan(withChurch(false).netYearCents));
    });
  });
}
