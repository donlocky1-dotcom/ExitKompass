import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

int eur(int euro) => euro * 100;

void main() {
  group('M6 – severance estimate', () {
    test('standard band: 3.500 € × 8 years (hand-computed)', () {
      final e = estimateSeverance(
        grossMonthCents: eur(3500),
        tenureYears: 8,
        age: 40,
        strength: NegotiationStrength.standard,
      );
      // base = 3.500 × 8 = 28.000; standard band 0.5–1.0
      expect(e.factorLow, 0.5);
      expect(e.factorHigh, 1.0);
      expect(e.lowCents, eur(14000));
      expect(e.highCents, eur(28000));
      expect(e.pointCents, eur(21000)); // midpoint of the band
      expect(e.regelabfindungCents, eur(14000)); // § 1a reference (0.5)
      expect(e.cappedByKschG10, isFalse);
    });

    test('weak position pushes the band down', () {
      final e = estimateSeverance(
        grossMonthCents: eur(4000),
        tenureYears: 5,
        age: 35,
        strength: NegotiationStrength.schwach,
      );
      // base 20.000; schwach 0.25–0.5
      expect(e.lowCents, eur(5000));
      expect(e.highCents, eur(10000));
    });

    test('strong position: 1.0–1.5', () {
      final e = estimateSeverance(
        grossMonthCents: eur(5000),
        tenureYears: 10,
        age: 45,
        strength: NegotiationStrength.stark,
      );
      // base 50.000; stark 1.0–1.5
      expect(e.lowCents, eur(50000));
      expect(e.highCents, eur(75000));
    });

    test('small business shades the band down by 0.25', () {
      final normal = estimateSeverance(
        grossMonthCents: eur(4000),
        tenureYears: 6,
        age: 40,
        strength: NegotiationStrength.standard,
      );
      final small = estimateSeverance(
        grossMonthCents: eur(4000),
        tenureYears: 6,
        age: 40,
        strength: NegotiationStrength.standard,
        smallBusiness: true,
      );
      // base 24.000; standard 0.5–1.0 → small 0.25–0.75
      expect(small.factorLow, 0.25);
      expect(small.factorHigh, 0.75);
      expect(small.lowCents, lessThan(normal.lowCents));
      expect(small.highCents, lessThan(normal.highCents));
      expect(small.smallBusiness, isTrue);
    });

    test('§ 10 KSchG cap: 15 months from age 50 with 15+ years', () {
      final e = estimateSeverance(
        grossMonthCents: eur(5000),
        tenureYears: 16,
        age: 52,
        strength: NegotiationStrength.stark,
      );
      // uncapped high = 1.5 × 5.000 × 16 = 120.000; cap = 15 × 5.000 = 75.000
      expect(e.kschG10CapMonths, 15);
      expect(e.cappedByKschG10, isTrue);
      expect(e.highCents, eur(75000));
    });

    test('§ 10 KSchG cap: 18 months from age 55 with 20+ years', () {
      final e = estimateSeverance(
        grossMonthCents: eur(6000),
        tenureYears: 25,
        age: 58,
        strength: NegotiationStrength.stark,
      );
      // cap = 18 × 6.000 = 108.000; uncapped high = 1.5 × 6.000 × 25 = 225.000
      expect(e.kschG10CapMonths, 18);
      expect(e.highCents, eur(108000));
    });

    test('no cap below the age/tenure thresholds', () {
      final e = estimateSeverance(
        grossMonthCents: eur(5000),
        tenureYears: 14,
        age: 49,
        strength: NegotiationStrength.stark,
      );
      expect(e.kschG10CapMonths, 0);
      expect(e.cappedByKschG10, isFalse);
    });

    test('range is ordered: low ≤ point ≤ high', () {
      for (final s in NegotiationStrength.values) {
        final e = estimateSeverance(
          grossMonthCents: eur(4500),
          tenureYears: 12,
          age: 51,
          strength: s,
        );
        expect(e.lowCents, lessThanOrEqualTo(e.pointCents));
        expect(e.pointCents, lessThanOrEqualTo(e.highCents));
      }
    });
  });
}
