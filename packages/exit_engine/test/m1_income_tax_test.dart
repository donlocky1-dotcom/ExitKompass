import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

/// Helper: whole euros → cents.
int eur(int euro) => euro * 100;

void main() {
  group('M1 – § 32a tariff 2026 (basic tariff)', () {
    test('basic allowance: no tax up to 12,348 €', () {
      expect(incomeTax(taxableIncomeCents: 0), 0);
      expect(incomeTax(taxableIncomeCents: eur(5000)), 0);
      expect(incomeTax(taxableIncomeCents: eur(12348)), 0);
      expect(incomeTax(taxableIncomeCents: 1234899), 0,
          reason: 'taxable income is rounded down to full euros');
    });

    test('negative taxable income is treated as 0', () {
      expect(incomeTax(taxableIncomeCents: -eur(10000)), 0);
    });

    test('entry into zone 2: 14 % entry rate', () {
      // (914.51 * 0.0001 + 1400) * 0.0001 = 0.1400... € -> floored to 0 €
      expect(incomeTax(taxableIncomeCents: eur(12349)), 0);
      // 10 € above the allowance: = 1.40 € -> 1 €
      expect(incomeTax(taxableIncomeCents: eur(12358)), eur(1));
    });

    test('anchor values of the progression zones (hand-computed)', () {
      expect(incomeTax(taxableIncomeCents: eur(15000)), eur(435));
      expect(incomeTax(taxableIncomeCents: eur(17799)), eur(1034)); // end of zone 2
      expect(incomeTax(taxableIncomeCents: eur(17800)), eur(1035)); // start of zone 3
      expect(incomeTax(taxableIncomeCents: eur(40000)), eur(7209));
      expect(incomeTax(taxableIncomeCents: eur(69878)), eur(18213)); // end of zone 3
    });

    test('proportional zones: 42 % and 45 % (top rate)', () {
      // 0.42 * 69,879 - 11,135.63 = 18,213.55 -> 18,213
      expect(incomeTax(taxableIncomeCents: eur(69879)), eur(18213));
      // 0.42 * 100,000 - 11,135.63 = 30,864.37
      expect(incomeTax(taxableIncomeCents: eur(100000)), eur(30864));
      // 0.45 * 300,000 - 19,470.38 = 115,529.62
      expect(incomeTax(taxableIncomeCents: eur(300000)), eur(115529));
    });

    test('tariff is (nearly) continuous at all zone bounds and monotonic', () {
      const bounds = [12348, 17799, 69878, 277825];
      for (final b in bounds) {
        final below = incomeTax(taxableIncomeCents: eur(b));
        final above = incomeTax(taxableIncomeCents: eur(b + 1));
        expect(above - below, inInclusiveRange(0, eur(1)),
            reason: 'jump at zone bound $b €');
      }
      var previous = 0;
      for (var income = 10000; income <= 320000; income += 5000) {
        final tax = incomeTax(taxableIncomeCents: eur(income));
        expect(tax, greaterThanOrEqualTo(previous), reason: 'monotonic at $income €');
        previous = tax;
      }
    });

    test('splitting tariff: double the tax on half the income', () {
      expect(incomeTax(taxableIncomeCents: eur(80000), splitting: true),
          2 * incomeTax(taxableIncomeCents: eur(40000)));
      expect(incomeTax(taxableIncomeCents: eur(80000), splitting: true), eur(14418));
      // Splitting advantage over the basic tariff
      expect(incomeTax(taxableIncomeCents: eur(80000), splitting: true),
          lessThan(incomeTax(taxableIncomeCents: eur(80000))));
    });
  });

  group('M1 – solidarity surcharge', () {
    test('no surcharge below the exemption limit', () {
      expect(solidaritySurcharge(assessmentBasisCents: eur(20350)), 0);
      expect(solidaritySurcharge(assessmentBasisCents: eur(15000)), 0);
    });

    test('taper zone: 11.9 % of the amount above the limit', () {
      // 1 € above the limit: 11.9 cents -> 11 cents (floored)
      expect(solidaritySurcharge(assessmentBasisCents: eur(20351)), 11);
      // 1,000 € above the limit: 119 €  <  5.5 % of 21,350 € = 1,174.25 €
      expect(solidaritySurcharge(assessmentBasisCents: eur(21350)), eur(119));
    });

    test('above the taper zone: full 5.5 % rate', () {
      // Zone ends where 11.9(E-F) = 5.5E -> E = 37,838.28 €
      expect(solidaritySurcharge(assessmentBasisCents: eur(40000)), eur(2200));
    });

    test('splitting / tax class III: doubled exemption limit', () {
      expect(solidaritySurcharge(assessmentBasisCents: eur(40700), splitting: true), 0);
      expect(solidaritySurcharge(assessmentBasisCents: eur(40700)), greaterThan(0));
    });
  });

  group('M1 – church tax', () {
    test('9 % by default, 8 % in Bavaria and Baden-Württemberg', () {
      expect(
          churchTax(
              assessmentBasisCents: eur(10000), state: Bundesland.nordrheinWestfalen),
          eur(900));
      expect(churchTax(assessmentBasisCents: eur(10000), state: Bundesland.bayern),
          eur(800));
      expect(
          churchTax(
              assessmentBasisCents: eur(10000), state: Bundesland.badenWuerttemberg),
          eur(800));
    });

    test('no church tax on 0', () {
      expect(churchTax(assessmentBasisCents: 0, state: Bundesland.bayern), 0);
    });
  });

  group('M1 – surcharge tax base (§ 51a EStG)', () {
    test('child allowances reduce the assessment basis', () {
      final withoutChild = surchargeTaxBase(taxableIncomeCents: eur(50000));
      final oneChild =
          surchargeTaxBase(taxableIncomeCents: eur(50000), childAllowanceFactor: 1);
      expect(withoutChild, incomeTax(taxableIncomeCents: eur(50000)));
      // factor 1.0 = 9,756 € allowance
      expect(oneChild, incomeTax(taxableIncomeCents: eur(50000 - 9756)));
      expect(oneChild, lessThan(withoutChild));
    });
  });

  group('M1 – Vorsorgepauschale (simplified)', () {
    test('60,000 € gross, class I, childless: pension + health + care', () {
      // pension 9.3 % = 5,580 | health (7.3+1.45) % = 5,250 | care (1.8+0.6) % = 1,440
      final vp = vorsorgepauschale(
        grossYearCents: eur(60000),
        taxClass: TaxClass.i,
        age: 30,
      );
      expect(vp, eur(5580 + 5250 + 1440));
    });

    test('capped at both contribution ceilings (130,000 € gross)', () {
      // pension: 9.3 % of 101,400 = 9,430.20 -> rounded up 9,431
      // health: 8.75 % of 69,750 = 6,103.125 -> 6,104
      // care: 2.4 % of 69,750 = 1,674
      final vp = vorsorgepauschale(
        grossYearCents: eur(130000),
        taxClass: TaxClass.i,
        age: 40,
      );
      expect(vp, eur(9431 + 6104 + 1674));
      // More gross does not change anything anymore
      expect(
          vorsorgepauschale(grossYearCents: eur(200000), taxClass: TaxClass.i, age: 40),
          vp);
    });

    test('children lower the care insurance part (2 children under 25)', () {
      final childless =
          vorsorgepauschale(grossYearCents: eur(60000), taxClass: TaxClass.iv, age: 40);
      final twoChildren = vorsorgepauschale(
        grossYearCents: eur(60000),
        taxClass: TaxClass.iv,
        age: 40,
        totalChildren: 2,
        childrenUnder25: 2,
      );
      // childless: care 2.4 % | 2 children: care 1.8 - 0.25 = 1.55 %
      expect(childless - twoChildren, eur((60000 * 0.024 - 60000 * 0.0155).round()));
    });
  });

  group('M1 – annual wage tax per tax class', () {
    test('class I, 60,000 € gross, childless (hand-computed)', () {
      final result = annualWageTax(
        grossYearCents: eur(60000),
        taxClass: TaxClass.i,
        age: 30,
      );
      // taxable = 60,000 - 1,230 - 36 - 12,270 = 46,464
      expect(result.taxableCents, eur(46464));
      expect(result.wageTaxCents, eur(9328));
      expect(result.soliCents, 0, reason: 'wage tax below the 20,350 € exemption');
      expect(result.churchTaxCents, 0, reason: 'not a church member');
    });

    test('class III pays much less than class I, class V more', () {
      WageTaxResult of(TaxClass taxClass) => annualWageTax(
            grossYearCents: eur(60000),
            taxClass: taxClass,
            age: 35,
          );
      final i = of(TaxClass.i).wageTaxCents;
      final iii = of(TaxClass.iii).wageTaxCents;
      final v = of(TaxClass.v).wageTaxCents;
      expect(iii, lessThan(i));
      expect(v, greaterThan(i));
    });

    test('class V: formula of § 39b Abs. 2 S. 7 (hand-computed, 45,000 € gross)', () {
      final result = annualWageTax(
        grossYearCents: eur(45000),
        taxClass: TaxClass.v,
        age: 30,
      );
      // VP = 4,185 (pension) + 3,938 (health) + 1,080 (care) = 9,203
      // taxable = 45,000 - 1,230 - 36 - 9,203 = 34,531
      expect(result.taxableCents, eur(34531));
      // 2*(T(43,163) - T(25,898)) = 2*(8,228 - 3,089) = 10,278 (cap not binding)
      expect(result.wageTaxCents, eur(10278));
    });

    test('class V: 14 % minimum rate applies at low income', () {
      final result = annualWageTax(
        grossYearCents: eur(15000),
        taxClass: TaxClass.v,
        age: 30,
      );
      // The taxable amount is far below the basic allowance; the base
      // formula would yield 0, the 14 % minimum does not.
      expect(result.wageTaxCents, greaterThan(0));
      expect(result.wageTaxCents / result.taxableCents, closeTo(0.14, 0.001));
    });

    test('class II: single-parent relief reduces the taxable amount', () {
      final i = annualWageTax(grossYearCents: eur(45000), taxClass: TaxClass.i, age: 35);
      final ii = annualWageTax(grossYearCents: eur(45000), taxClass: TaxClass.ii, age: 35);
      expect(i.taxableCents - ii.taxableCents, eur(4260));
    });

    test('class VI: no lump sums', () {
      final vi = annualWageTax(grossYearCents: eur(45000), taxClass: TaxClass.vi, age: 35);
      final v = annualWageTax(grossYearCents: eur(45000), taxClass: TaxClass.v, age: 35);
      expect(v.taxableCents - vi.taxableCents, -eur(1230 + 36));
    });

    test('child allowances only affect soli/church tax, not the wage tax', () {
      final without = annualWageTax(
        grossYearCents: eur(95000),
        taxClass: TaxClass.i,
        age: 40,
        churchMember: true,
      );
      final withChildren = annualWageTax(
        grossYearCents: eur(95000),
        taxClass: TaxClass.i,
        age: 40,
        churchMember: true,
        childAllowanceFactor: 2,
        totalChildren: 2,
        childrenUnder25: 2,
      );
      expect(withChildren.wageTaxCents, greaterThanOrEqualTo(without.wageTaxCents),
          reason: 'child allowances do not lower the wage tax; the care insurance '
              'child discounts even shrink the Vorsorgepauschale and slightly '
              'raise the wage tax');
      expect(withChildren.soliCents, lessThan(without.soliCents));
      expect(withChildren.churchTaxCents, lessThan(without.churchTaxCents));
    });
  });
}
