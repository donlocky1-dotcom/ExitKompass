import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

int eur(int euro) => euro * 100;

/// A reference employee: 5,000 €/month gross, class I, childless, age 40,
/// 10 years of tenure, exit in 3 months, regular end also in 3 months
/// (notice period observed).
UserProfile _profile() => const UserProfile(
      birthYear: 1986,
      taxClass: TaxClass.i,
      state: Bundesland.nordrheinWestfalen,
    );

EmploymentData _employment() => EmploymentData(
      grossMonthCents: eur(5000),
      entryDate: DateTime(2016, 1, 1),
      regularEndDate: DateTime(2026, 4, 1),
    );

OfferData _offer({
  int severance = 50000,
  DateTime? exit,
  bool release = false,
  bool anticipates = false,
}) =>
    OfferData(
      severanceGrossCents: eur(severance),
      exitDate: exit ?? DateTime(2026, 4, 1),
      paidRelease: release,
      anticipatesOperationalDismissal: anticipates,
    );

AggregateResult _aggregate({OfferData? offer, EmploymentData? employment}) =>
    aggregateScenarios(
      profile: _profile(),
      employment: employment ?? _employment(),
      offer: offer ?? _offer(),
      referenceDate: DateTime(2026, 1, 1),
      horizonMonths: 24,
    );

void main() {
  group('M5 – structure', () {
    test('all four scenarios are produced, each with a full-horizon timeline', () {
      final r = _aggregate();
      expect(r.scenarios.keys.toSet(), ScenarioType.values.toSet());
      for (final s in r.scenarios.values) {
        expect(s.monthlyNetCents, hasLength(24));
        expect(s.monthlySource, hasLength(24));
      }
    });
  });

  group('M5 – S4 baseline (staying employed)', () {
    test('every month is net salary, cumulative = 24 × monthly net', () {
      final r = _aggregate();
      final base = r.baseline;
      final monthly = base.monthlyNetCents.first;
      expect(monthly, greaterThan(0));
      expect(base.monthlyNetCents.every((m) => m == monthly), isTrue);
      expect(base.cumulativeNetCents, monthly * 24);
      expect(base.monthlySource.every((s) => s == CashflowSource.salary), isTrue);
      expect(base.flags, isEmpty);
    });
  });

  group('M5 – S1 employer dismissal (downside: no severance, no blocking)', () {
    test('salary until the regular notice end, then ALG – no severance inflow', () {
      final r = _aggregate();
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      // Salary runs to the regular end (month 3), then ALG right after.
      expect(s1.monthlySource[0], CashflowSource.salary);
      expect(s1.monthlySource[2], CashflowSource.salary);
      expect(s1.monthlySource[3], CashflowSource.alg);
      // The employer dismissal carries no negotiated severance.
      expect(s1.monthlySource.contains(CashflowSource.severance), isFalse);
      expect(s1.flags.any((f) => f.code == 'fuenftel_erstattung'), isFalse);
    });

    test('no blocking-period flag, but a downside note is attached', () {
      final r = _aggregate();
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      expect(s1.flags.any((f) => f.code.startsWith('sperrzeit')), isFalse);
      expect(s1.flags.any((f) => f.code == 'kuendigung_ag_downside'), isTrue);
    });

    test('a large negotiated offer does NOT lift S1 (severance is S2 only)', () {
      final r = _aggregate(offer: _offer(severance: 200000));
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      expect(s1.monthlySource.contains(CashflowSource.severance), isFalse);
      // S1 never beats staying – it is salary until notice end, then ALG.
      expect(s1.cumulativeNetCents, lessThan(r.baseline.cumulativeNetCents));
    });
  });

  group('M5 – S2 termination agreement (severance)', () {
    test('salary until exit, severance lump in the exit month, refund ~a year later',
        () {
      final r = _aggregate(offer: _offer(severance: 60000, anticipates: true));
      final s2 = r.scenarios[ScenarioType.aufhebungsvertrag]!;
      expect(s2.monthlySource[0], CashflowSource.salary);
      expect(s2.monthlySource[2], CashflowSource.salary);
      expect(s2.monthlySource[3], CashflowSource.severance);
      expect(s2.monthlyNetCents[3], greaterThan(s2.monthlyNetCents[0]));
      expect(s2.flags.any((f) => f.code == 'fuenftel_erstattung'), isTrue);
      // exit at month 3 -> refund at month 15
      expect(s2.monthlySource[15], CashflowSource.severanceRefund);
      expect(s2.monthlyNetCents[15], greaterThan(0));
    });

    test('anticipated operational dismissal + modest severance → blocking unlikely',
        () {
      // 0.5 monthly salaries × 10 years = 25,000 € is within the corridor,
      // notice observed (exit == regular end), dismissal anticipated.
      final r = _aggregate(offer: _offer(severance: 25000, anticipates: true));
      final s2 = r.scenarios[ScenarioType.aufhebungsvertrag]!;
      expect(s2.flags.any((f) => f.code == 'sperrzeit_unwahrscheinlich'), isTrue);
    });

    test('without an anticipated dismissal → blocking likely, even if modest', () {
      final r = _aggregate(offer: _offer(severance: 25000, anticipates: false));
      final s2 = r.scenarios[ScenarioType.aufhebungsvertrag]!;
      expect(s2.flags.any((f) => f.code == 'sperrzeit_wahrscheinlich'), isTrue);
    });

    test('anticipated dismissal but large severance → blocking likely', () {
      final r = _aggregate(offer: _offer(severance: 120000, anticipates: true));
      final s2 = r.scenarios[ScenarioType.aufhebungsvertrag]!;
      expect(s2.flags.any((f) => f.code == 'sperrzeit_wahrscheinlich'), isTrue);
    });

    test('§ 158 suspension when the exit is before the regular end date', () {
      final employment = EmploymentData(
        grossMonthCents: eur(5000),
        entryDate: DateTime(2016, 1, 1),
        regularEndDate: DateTime(2026, 10, 1), // regular end far later
      );
      final offer = _offer(severance: 50000, exit: DateTime(2026, 4, 1));
      final r = _aggregate(employment: employment, offer: offer);
      final s2 = r.scenarios[ScenarioType.aufhebungsvertrag]!;
      expect(s2.flags.any((f) => f.code == 'ruhen_158'), isTrue);
    });
  });

  group('M5 – S3 resignation (blocking period, no severance)', () {
    test('no severance inflow, blocking period delays ALG and shortens it', () {
      final r = _aggregate();
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      final s3 = r.scenarios[ScenarioType.eigenkuendigung]!;
      expect(s3.flags.any((f) => f.code == 'sperrzeit_eigenkuendigung'), isTrue);
      expect(s3.monthlySource.contains(CashflowSource.severance), isFalse);
      // ALG starts later than in S1 (12-week blocking period ≈ 3 months).
      final s1AlgStart = s1.monthlySource.indexOf(CashflowSource.alg);
      final s3AlgStart = s3.monthlySource.indexOf(CashflowSource.alg);
      expect(s3AlgStart, greaterThan(s1AlgStart));
      expect(s3.cumulativeNetCents, lessThan(s1.cumulativeNetCents));
    });
  });

  group('M5 – aggregation (deltas and best scenario)', () {
    test('deltas are relative to the baseline; baseline delta is 0', () {
      final r = _aggregate();
      expect(r.deltaToBaselineCents(ScenarioType.bleiben), 0);
      expect(r.deltaToBaselineCents(ScenarioType.eigenkuendigung), isNegative);
    });

    test('the best scenario is an exit option, never the "stay" baseline', () {
      // Even though staying trivially has the highest cumulative net, the
      // star goes to the best actionable exit option.
      final r = _aggregate(offer: _offer(severance: 25000, anticipates: true));
      expect(r.bestScenario, isNot(ScenarioType.bleiben));
    });

    test('with a large severance the termination agreement can beat staying', () {
      final r = _aggregate(offer: _offer(severance: 200000, anticipates: true));
      expect(r.scenarios[ScenarioType.aufhebungsvertrag]!.cumulativeNetCents,
          greaterThan(r.baseline.cumulativeNetCents));
      expect(r.bestScenario, ScenarioType.aufhebungsvertrag);
    });

    test('a gap without income raises the health-insurance flag', () {
      // Short entitlement (short tenure) leaves a gap before the horizon ends.
      final employment = EmploymentData(
        grossMonthCents: eur(5000),
        entryDate: DateTime(2024, 7, 1), // ~21 months tenure at exit
        regularEndDate: DateTime(2026, 4, 1),
      );
      final r = _aggregate(employment: employment);
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      expect(s1.monthlySource.contains(CashflowSource.gap), isTrue);
      expect(s1.flags.any((f) => f.code == 'kv_luecke'), isTrue);
    });
  });

  group('M5 – paid release (Freistellung) on the termination agreement', () {
    // Exit already at month 3, but the regular end (and thus the paid
    // release) runs until month 9.
    EmploymentData employmentReleaseUntil9() => EmploymentData(
          grossMonthCents: eur(5000),
          entryDate: DateTime(2016, 1, 1),
          regularEndDate: DateTime(2026, 10, 1), // 9 months after reference
        );
    // Modest, in-corridor severance so blocking does not confound the paid
    // release assertions (ALG starts right after the regular end).
    OfferData offerExit3(bool release) => _offer(
        severance: 25000,
        exit: DateTime(2026, 4, 1),
        release: release,
        anticipates: true);

    test('salary continues to the regular end and severance lands there', () {
      final r = _aggregate(
        employment: employmentReleaseUntil9(),
        offer: offerExit3(true),
      );
      final s2 = r.scenarios[ScenarioType.aufhebungsvertrag]!;
      // Salary runs through month 8 (regular end at month 9), not month 3.
      expect(s2.monthlySource[3], CashflowSource.salary);
      expect(s2.monthlySource[8], CashflowSource.salary);
      expect(s2.monthlySource[9], CashflowSource.severance);
      // ALG only after the regular end.
      expect(s2.monthlySource[10], CashflowSource.alg);
      expect(s2.flags.any((f) => f.code == 'freistellung'), isTrue);
    });

    test('paid release beats the same offer without release (more salary months)',
        () {
      final withRelease = _aggregate(
        employment: employmentReleaseUntil9(),
        offer: offerExit3(true),
      ).scenarios[ScenarioType.aufhebungsvertrag]!;
      final withoutRelease = _aggregate(
        employment: employmentReleaseUntil9(),
        offer: offerExit3(false),
      ).scenarios[ScenarioType.aufhebungsvertrag]!;
      expect(withRelease.cumulativeNetCents,
          greaterThan(withoutRelease.cumulativeNetCents));
    });

    test('paid release suppresses the § 158 suspension (notice period observed)', () {
      final withoutRelease = _aggregate(
        employment: employmentReleaseUntil9(),
        offer: offerExit3(false),
      ).scenarios[ScenarioType.aufhebungsvertrag]!;
      expect(withoutRelease.flags.any((f) => f.code == 'ruhen_158'), isTrue);

      final withRelease = _aggregate(
        employment: employmentReleaseUntil9(),
        offer: offerExit3(true),
      ).scenarios[ScenarioType.aufhebungsvertrag]!;
      expect(withRelease.flags.any((f) => f.code == 'ruhen_158'), isFalse);
    });

    test('resignation (S3) ignores paid release', () {
      final r = _aggregate(
        employment: employmentReleaseUntil9(),
        offer: offerExit3(true),
      );
      final s3 = r.scenarios[ScenarioType.eigenkuendigung]!;
      // Salary ends at the chosen exit (month 3), no freistellung flag.
      expect(s3.monthlySource[3], isNot(CashflowSource.salary));
      expect(s3.flags.any((f) => f.code == 'freistellung'), isFalse);
    });
  });
}
