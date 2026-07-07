import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

int eur(int euro) => euro * 100;

void main() {
  group('M3 – Fünftelregelung vs. regular taxation', () {
    test('40,000 € taxable + 50,000 € severance (hand-computed)', () {
      final r = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(40000),
        severanceCents: eur(50000),
      );
      expect(r.taxWithoutSeveranceCents, eur(7209));
      // regular: T(90,000) = 0.42 * 90,000 - 11,135.63 = 26,664.37 -> 26,664
      expect(r.taxRegularCents, eur(26664));
      // one-fifth: 7,209 + 5 * (T(50,000) - 7,209) = 7,209 + 5 * (10,548 - 7,209)
      expect(r.taxFifthRuleCents, eur(23904));
      expect(r.savingsCents, eur(2760));
      expect(r.refundOnlyViaTaxReturn, isTrue);
    });

    test('largest effect: low income, severance fifth below the basic allowance', () {
      final r = severanceComparison(
        taxableIncomeWithoutSeveranceCents: 0,
        severanceCents: eur(20000),
      );
      // T(20,000) = 1,570; one fifth (4,000 €) stays below the basic
      // allowance -> fifth-rule tax 0.
      expect(r.taxRegularCents, eur(1570));
      expect(r.taxFifthRuleCents, 0);
      expect(r.savingsCents, eur(1570));
    });

    test('no benefit when rest income and top are in the 42 % zone', () {
      final r = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(100000),
        severanceCents: eur(100000),
      );
      expect(r.taxRegularCents, eur(72864));
      expect(r.taxFifthRuleCents, r.taxRegularCents,
          reason: 'linear tariff: 5 * 0.42 * A/5 = 0.42 * A');
      expect(r.savingsCents, 0);
      expect(r.refundOnlyViaTaxReturn, isFalse);
    });

    test('top tax rate: the one-fifth rule keeps the severance below the 45 % zone',
        () {
      final r = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(250000),
        severanceCents: eur(100000),
      );
      expect(r.taxRegularCents, eur(138029));
      expect(r.taxFifthRuleCents, eur(135864));
      expect(r.savingsCents, eur(2165));
    });

    test('severance 0: all variants identical', () {
      final r = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(40000),
        severanceCents: 0,
      );
      expect(r.taxRegularCents, r.taxWithoutSeveranceCents);
      expect(r.taxFifthRuleCents, r.taxWithoutSeveranceCents);
      expect(r.savingsCents, 0);
      expect(r.refundOnlyViaTaxReturn, isFalse);
    });

    test('splitting: the comparison consistently uses the splitting tariff', () {
      final r = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(80000),
        severanceCents: eur(60000),
        splitting: true,
      );
      expect(r.taxWithoutSeveranceCents,
          incomeTax(taxableIncomeCents: eur(80000), splitting: true));
      expect(r.taxRegularCents,
          incomeTax(taxableIncomeCents: eur(140000), splitting: true));
      expect(r.savingsCents, greaterThan(0));
    });

    test('tax shares of the severance are consistent', () {
      final r = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(40000),
        severanceCents: eur(50000),
      );
      expect(r.taxOnSeveranceRegularCents,
          r.taxRegularCents - r.taxWithoutSeveranceCents);
      expect(r.taxOnSeveranceFifthRuleCents,
          r.taxOnSeveranceRegularCents - r.savingsCents);
    });

    test('negative rest income is treated as 0', () {
      final r = severanceComparison(
        taxableIncomeWithoutSeveranceCents: -eur(5000),
        severanceCents: eur(20000),
      );
      expect(r.taxableIncomeWithoutSeveranceCents, 0);
      expect(r.taxFifthRuleCents, 0);
    });
  });

  group('M3 – income bunching check (spec §5, M3)', () {
    test('bunching given: severance + income in year exceeds foregone income', () {
      expect(
          incomeBunchingGiven(
            severanceCents: eur(50000),
            otherIncomeYearCents: eur(30000), // wage Jan–Jun
            foregoneIncomeCents: eur(60000), // full-year wage
          ),
          isTrue);
    });

    test('bunching not given: small severance late in the year', () {
      expect(
          incomeBunchingGiven(
            severanceCents: eur(5000),
            otherIncomeYearCents: eur(10000),
            foregoneIncomeCents: eur(60000),
          ),
          isFalse);
    });

    test('not checked without the optional inputs', () {
      final r = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(40000),
        severanceCents: eur(50000),
      );
      expect(r.fifthRuleApplicable, isNull);
    });

    test('wired into the comparison result when inputs are provided', () {
      final applicable = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(30000),
        severanceCents: eur(50000),
        otherIncomeYearCents: eur(30000),
        foregoneIncomeCents: eur(60000),
      );
      expect(applicable.fifthRuleApplicable, isTrue);

      final notApplicable = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(30000),
        severanceCents: eur(5000),
        otherIncomeYearCents: eur(30000),
        foregoneIncomeCents: eur(60000),
      );
      expect(notApplicable.fifthRuleApplicable, isFalse);
    });
  });

  group('M3 – Progressionsvorbehalt (§ 32b) on the severance', () {
    test('same-year ALG raises the tax attributed to the severance', () {
      final without = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(40000),
        severanceCents: eur(50000),
      );
      final withAlg = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(40000),
        severanceCents: eur(50000),
        progressionIncomeCents: eur(12000), // ~8 months ALG in the same year
      );
      expect(withAlg.taxRegularCents, greaterThan(without.taxRegularCents));
      expect(withAlg.taxFifthRuleCents, greaterThan(without.taxFifthRuleCents));
      expect(withAlg.taxOnSeveranceFifthRuleCents,
          greaterThan(without.taxOnSeveranceFifthRuleCents));
    });

    test('zero progression income equals the plain comparison', () {
      final plain = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(40000),
        severanceCents: eur(50000),
      );
      final zeroProg = severanceComparison(
        taxableIncomeWithoutSeveranceCents: eur(40000),
        severanceCents: eur(50000),
        progressionIncomeCents: 0,
      );
      expect(zeroProg.taxRegularCents, plain.taxRegularCents);
      expect(zeroProg.taxFifthRuleCents, plain.taxFifthRuleCents);
    });
  });
}
