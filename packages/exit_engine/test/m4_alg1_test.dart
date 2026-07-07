import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

int eur(int euro) => euro * 100;

void main() {
  group('M4 – ALG 1 benefit assessment', () {
    test('60,000 € gross, class I, childless, age 30 (hand-computed)', () {
      final alg = alg1Benefit(
        grossYearCents: eur(60000),
        taxClass: TaxClass.i,
        age: 30,
      );
      expect(alg.assessedGrossYearCents, eur(60000));
      expect(alg.assessedGrossDayCents, 16438, reason: '60,000 € / 365 = 164.38 €');
      expect(alg.socialLumpYearCents, eur(12000), reason: '20 % social lump sum');
      expect(alg.wageTaxYearCents, eur(9389), reason: 'notional wage tax as in M1');
      expect(alg.soliYearCents, 0);
      // benefit wage: (60,000 - 12,000 - 9,389) / 365 = 105.78 €/day
      expect(alg.benefitBaseDayCents, 10578);
      expect(alg.benefitRate, 0.60);
      expect(alg.benefitDayCents, 6346, reason: '60 % of 105.78 €');
      expect(alg.benefitMonthCents, 190380, reason: '30 daily rates = 1,903.80 €/month');
    });

    test('130,000 € gross: assessment wage capped at the ceiling', () {
      final alg = alg1Benefit(
        grossYearCents: eur(130000),
        taxClass: TaxClass.i,
        age: 40,
      );
      expect(alg.assessedGrossYearCents, eur(101400), reason: 'ceiling cap');
      // wage tax on 101,400 € (class I): 23,781 €; soli 408.28 €
      expect(alg.wageTaxYearCents, eur(23781));
      expect(alg.soliYearCents, 40828);
      // benefit wage = (101,400 - 20,280 - 23,781 - 408.28) / 365 = 155.97 €/day
      expect(alg.benefitBaseDayCents, 15597);
      expect(alg.benefitDayCents, 9358);
      expect(alg.benefitMonthCents, 280740, reason: 'max ALG childless: 2,807.40 €/month');
    });

    test('more gross above the ceiling no longer changes the benefit', () {
      Alg1Assessment of(int gross) =>
          alg1Benefit(grossYearCents: eur(gross), taxClass: TaxClass.i, age: 40);
      expect(of(101400).benefitMonthCents, of(200000).benefitMonthCents);
    });

    test('increased benefit rate 67 % with child', () {
      Alg1Assessment of({required bool child}) => alg1Benefit(
            grossYearCents: eur(60000),
            taxClass: TaxClass.i,
            age: 35,
            hasChild: child,
          );
      final without = of(child: false);
      final increased = of(child: true);
      expect(increased.benefitRate, 0.67);
      expect(increased.benefitDayCents, rateFloor(increased.benefitBaseDayCents, 0.67));
      expect(increased.benefitMonthCents, greaterThan(without.benefitMonthCents));
    });

    test('tax class V lowers the benefit considerably compared to III', () {
      Alg1Assessment of(TaxClass taxClass) =>
          alg1Benefit(grossYearCents: eur(60000), taxClass: taxClass, age: 35);
      expect(of(TaxClass.v).benefitMonthCents, lessThan(of(TaxClass.iii).benefitMonthCents));
    });
  });

  group('M4 – entitlement duration (§ 147 SGB III)', () {
    int duration(int months, int age) =>
        alg1EntitlementDays(insuredMonths: months, age: age);

    test('qualifying period not met: no entitlement below 12 months', () {
      expect(duration(11, 40), 0);
    });

    test('base tiers without age condition', () {
      expect(duration(12, 25), 180);
      expect(duration(15, 25), 180);
      expect(duration(16, 25), 240);
      expect(duration(20, 25), 300);
      expect(duration(24, 30), 360);
      expect(duration(48, 49), 360, reason: 'below 50 it stays at 12 months');
    });

    test('extended durations from 50/55/58 only with age AND insured months', () {
      expect(duration(30, 50), 450);
      expect(duration(30, 49), 360);
      expect(duration(36, 55), 540);
      expect(duration(36, 54), 450, reason: '54 < 55: only the 50+ tier');
      expect(duration(48, 58), 720);
      expect(duration(48, 57), 540, reason: '57 < 58: only the 55+ tier');
      expect(duration(47, 58), 540, reason: '47 months are not enough for 720 days');
    });
  });

  group('M4 – blocking period (§ 159 / § 148 SGB III)', () {
    test('12-week blocking period, reduction at least one quarter', () {
      final s = blockingPeriodSimulation(entitlementDays: 360, benefitDayCents: 6357);
      expect(s.blockingDays, 84);
      expect(s.reductionDays, 90, reason: '360/4 = 90 > 84');
      expect(s.remainingEntitlementDays, 270);
      expect(s.lostBenefitCents, 90 * 6357);
    });

    test('for short entitlements the blocking period itself dominates', () {
      final s = blockingPeriodSimulation(entitlementDays: 180, benefitDayCents: 5000);
      expect(s.reductionDays, 84, reason: '180/4 = 45 < 84 blocking days');
      expect(s.remainingEntitlementDays, 96);
    });

    test('720 days entitlement: reduction of 180 days (half a year!)', () {
      final s = blockingPeriodSimulation(entitlementDays: 720, benefitDayCents: 9374);
      expect(s.reductionDays, 180);
      expect(s.remainingEntitlementDays, 540);
      expect(s.lostBenefitCents, 180 * 9374);
    });
  });

  group('M4 – blocking period heuristic (spec §5, M4)', () {
    test('termination agreement to avert an operational dismissal, notice '
        'observed, severance within 0.5 monthly salaries per year of tenure: '
        'blocking period unlikely', () {
      expect(
          blockingPeriodUnlikely(
            dismissalWasThreatened: true,
            noticePeriodObserved: true,
            severanceCents: eur(25000), // exactly 0.5 * 5,000 € * 10 years
            grossMonthCents: eur(5000),
            tenureYears: 10,
          ),
          isTrue);
    });

    test('severance above the 0.5 threshold: no exemption', () {
      expect(
          blockingPeriodUnlikely(
            dismissalWasThreatened: true,
            noticePeriodObserved: true,
            severanceCents: eur(25001),
            grossMonthCents: eur(5000),
            tenureYears: 10,
          ),
          isFalse);
    });

    test('notice period not observed: no exemption even if dismissal threatened',
        () {
      expect(
          blockingPeriodUnlikely(
            dismissalWasThreatened: true,
            noticePeriodObserved: false,
            severanceCents: eur(10000),
            grossMonthCents: eur(5000),
            tenureYears: 10,
          ),
          isFalse);
    });

    test('no threatened dismissal: heuristic never applies', () {
      expect(
          blockingPeriodUnlikely(
            dismissalWasThreatened: false,
            noticePeriodObserved: true,
            severanceCents: eur(1000),
            grossMonthCents: eur(5000),
            tenureYears: 10,
          ),
          isFalse);
    });
  });

  group('M4 – suspension on severance (§ 158 SGB III)', () {
    test('notice period observed: no suspension', () {
      final r = suspension158(
        severanceCents: eur(50000),
        age: 40,
        tenureYears: 10,
        dailyWageCents: 16438,
        missedNoticeDays: 0,
      );
      expect(r.suspensionDays, 0);
    });

    test('applicable share: 60 % minus 5 pp steps for age and tenure', () {
      final r = suspension158(
        severanceCents: eur(50000),
        age: 40,
        tenureYears: 10,
        dailyWageCents: 16438,
        missedNoticeDays: 60,
      );
      // 60 % - 2*5 % (10 years tenure) - 1*5 % (age 40 = 5 years over 35) = 45 %
      expect(r.applicableShare, 0.45);
      expect(r.severanceShareCents, eur(22500));
      // 22,500 € / 164.38 € = 136 days, but capped by the 60 missed days
      expect(r.suspensionDaysUncapped, 136);
      expect(r.suspensionDays, 60);
    });

    test('a small severance is consumed before the notice period ends', () {
      final r = suspension158(
        severanceCents: eur(5000),
        age: 40,
        tenureYears: 10,
        dailyWageCents: 16438,
        missedNoticeDays: 90,
      );
      // 45 % of 5,000 € = 2,250 € / 164.38 € = 13 days
      expect(r.suspensionDays, 13);
    });

    test('25 % floor at high age and long tenure', () {
      final r = suspension158(
        severanceCents: eur(50000),
        age: 63,
        tenureYears: 30,
        dailyWageCents: 16438,
        missedNoticeDays: 200,
      );
      expect(r.applicableShare, 0.25);
    });

    test('suspension is capped at one year', () {
      final r = suspension158(
        severanceCents: eur(500000),
        age: 30,
        tenureYears: 4,
        dailyWageCents: 16438,
        missedNoticeDays: 500,
      );
      expect(r.applicableShare, 0.60);
      expect(r.suspensionDays, 365);
    });
  });
}
