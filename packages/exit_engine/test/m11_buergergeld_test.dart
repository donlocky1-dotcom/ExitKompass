import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

int eur(int euro) => euro * 100;

void main() {
  final bg = BuergergeldParams.year2026();

  group('M11 – asset allowance (§ 12 SGB II)', () {
    test('Karenzzeit allowance higher than the ordinary one', () {
      final inKarenz = bg.assetAllowanceCents(monthsReceived: 0);
      final after = bg.assetAllowanceCents(monthsReceived: bg.karenzMonths);
      expect(inKarenz, eur(40000));
      expect(after, eur(15000));
      expect(inKarenz, greaterThan(after));
    });

    test('household size scales the allowance', () {
      // Karenzzeit: first person 40k + each further 15k.
      expect(bg.assetAllowanceCents(monthsReceived: 0, householdSize: 2),
          eur(40000) + eur(15000));
      // After: 15k per person.
      expect(bg.assetAllowanceCents(monthsReceived: 12, householdSize: 3),
          eur(45000));
    });

    test('monthly benefit adds KdU on top of the standard requirement', () {
      expect(bg.monthlyBenefitCents(), eur(563));
      expect(bg.monthlyBenefitCents(kduMonthlyCents: eur(700)), eur(1263));
    });
  });

  group('M11 – integration into the scenario horizon (M5)', () {
    UserProfile profile() => const UserProfile(
          birthYear: 1990,
          taxClass: TaxClass.i,
          state: Bundesland.nordrheinWestfalen,
        );
    // Short tenure → short ALG entitlement → a gap opens before month 36.
    EmploymentData employment() => EmploymentData(
          grossMonthCents: eur(4000),
          entryDate: DateTime(2024, 7, 1),
          regularEndDate: DateTime(2026, 4, 1),
        );
    OfferData offer() => OfferData(
          severanceGrossCents: eur(10000),
          exitDate: DateTime(2026, 4, 1),
        );

    AggregateResult run({required int savings, required int expenses}) =>
        aggregateScenarios(
          profile: profile(),
          employment: employment(),
          offer: offer(),
          referenceDate: DateTime(2026, 1, 1),
          horizonMonths: 36,
          includeBuergergeld: true,
          startingAssetsCents: savings,
          monthlyExpensesCents: expenses,
        );

    test('low assets → Bürgergeld fills part of the post-ALG gap', () {
      final r = run(savings: eur(5000), expenses: eur(1800));
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      expect(s1.monthlySource.contains(CashflowSource.buergergeld), isTrue);
      expect(s1.flags.any((f) => f.code == 'buergergeld'), isTrue);
    });

    test('high assets → no Bürgergeld (means test not met)', () {
      final r = run(savings: eur(80000), expenses: eur(1800));
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      expect(s1.monthlySource.contains(CashflowSource.buergergeld), isFalse);
      expect(s1.flags.any((f) => f.code == 'buergergeld'), isFalse);
    });

    test('disabled by default (backward compatible)', () {
      final r = aggregateScenarios(
        profile: profile(),
        employment: employment(),
        offer: offer(),
        referenceDate: DateTime(2026, 1, 1),
        horizonMonths: 36,
      );
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      expect(s1.monthlySource.contains(CashflowSource.buergergeld), isFalse);
    });
  });
}
