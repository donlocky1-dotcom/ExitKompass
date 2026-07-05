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

OfferData _offer({int severance = 50000, DateTime? exit, bool release = false}) =>
    OfferData(
      severanceGrossCents: eur(severance),
      exitDate: exit ?? DateTime(2026, 4, 1),
      paidRelease: release,
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

  group('M5 – S1 dismissal (severance + ALG, no blocking period)', () {
    test('salary until exit, severance lump in the exit month, then ALG', () {
      final r = _aggregate();
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      // Exit is 3 months after the reference date.
      expect(s1.monthlySource[0], CashflowSource.salary);
      expect(s1.monthlySource[2], CashflowSource.salary);
      expect(s1.monthlySource[3], CashflowSource.severance);
      // ALG follows right after the exit (no blocking period).
      expect(s1.monthlySource[4], CashflowSource.alg);
      // The severance month is the largest inflow.
      expect(s1.monthlyNetCents[3], greaterThan(s1.monthlyNetCents[0]));
    });

    test('a Fünftel refund flag is raised and the refund lands ~a year later', () {
      final r = _aggregate(offer: _offer(severance: 60000));
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      expect(s1.flags.any((f) => f.code == 'fuenftel_erstattung'), isTrue);
      // exit at month 3 -> refund at month 15
      expect(s1.monthlySource[15], CashflowSource.severanceRefund);
      expect(s1.monthlyNetCents[15], greaterThan(0));
    });

    test('no blocking-period flag for an employer dismissal', () {
      final r = _aggregate();
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      expect(s1.flags.any((f) => f.code.startsWith('sperrzeit')), isFalse);
    });
  });

  group('M5 – S3 resignation (blocking period, no severance)', () {
    test('no severance inflow, blocking period delays ALG and shortens it', () {
      final r = _aggregate();
      final s1 = r.scenarios[ScenarioType.kuendigungAg]!;
      final s3 = r.scenarios[ScenarioType.eigenkuendigung]!;
      expect(s3.flags.any((f) => f.code == 'sperrzeit_eigenkuendigung'), isTrue);
      // No severance month.
      expect(s3.monthlySource.contains(CashflowSource.severance), isFalse);
      // ALG starts later than in S1 (12-week blocking period ≈ 3 months).
      final s1AlgStart = s1.monthlySource.indexOf(CashflowSource.alg);
      final s3AlgStart = s3.monthlySource.indexOf(CashflowSource.alg);
      expect(s3AlgStart, greaterThan(s1AlgStart));
      // And S3's cumulative net is clearly lower.
      expect(s3.cumulativeNetCents, lessThan(s1.cumulativeNetCents));
    });
  });

  group('M5 – S2 termination agreement', () {
    test('modest severance to avert dismissal → blocking period unlikely flag', () {
      // 0.5 monthly salaries × 10 years = 25,000 € is within the threshold.
      final r = _aggregate(offer: _offer(severance: 25000));
      final s2 = r.scenarios[ScenarioType.aufhebungsvertrag]!;
      expect(s2.flags.any((f) => f.code == 'sperrzeit_unwahrscheinlich'), isTrue);
    });

    test('large severance → blocking period likely flag', () {
      final r = _aggregate(offer: _offer(severance: 120000));
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

  group('M5 – aggregation (deltas and best scenario)', () {
    test('deltas are relative to the baseline; baseline delta is 0', () {
      final r = _aggregate();
      expect(r.deltaToBaselineCents(ScenarioType.bleiben), 0);
      expect(r.deltaToBaselineCents(ScenarioType.eigenkuendigung), isNegative);
    });

    test('with a large severance the dismissal scenario can beat staying', () {
      final r = _aggregate(offer: _offer(severance: 200000));
      expect(r.scenarios[ScenarioType.kuendigungAg]!.cumulativeNetCents,
          greaterThan(r.baseline.cumulativeNetCents));
      expect(r.bestScenario, ScenarioType.kuendigungAg);
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
}
