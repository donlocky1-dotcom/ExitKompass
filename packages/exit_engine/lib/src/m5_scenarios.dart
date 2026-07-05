/// M5 – Scenario aggregator.
///
/// Turns a user profile plus employment and offer data into a monthly
/// net cashflow for each of the four core scenarios (spec §3):
///
/// * S1 `kuendigungAg`       – dismissal by the employer, salary until
///   the exit date + severance (Fünftelregelung) + ALG 1 without a
///   blocking period,
/// * S2 `aufhebungsvertrag`  – termination agreement: like S1, but with a
///   blocking-period risk flag and, if the notice period is shortened,
///   a benefit suspension per § 158,
/// * S3 `eigenkuendigung`    – resignation: 12-week blocking period plus a
///   one-quarter reduction of the entitlement, no severance,
/// * S4 `bleiben`            – staying employed (reference baseline).
///
/// The aggregator works on **month offsets** (month 0 = the reference
/// month of the observation horizon). Calendar dates from the domain
/// model are converted to offsets internally; exact day-level calendar
/// handling is left to the caller/UI (see ASSUMPTIONS.md A7). All amounts
/// are `int` cents.
library;

import 'dart:math';

import 'm1_income_tax.dart';
import 'm3_severance.dart';
import 'm4_alg1.dart';
import 'net_income.dart';
import 'params.dart';

/// Type of statutory (GKV) or private (PKV) health insurance.
enum KvArt { gesetzlich, privat }

/// The four core scenarios of the ExitKompass (spec §3).
enum ScenarioType {
  /// S1 – dismissal by the employer (with severance, no blocking period).
  kuendigungAg,

  /// S2 – termination agreement (blocking-period risk, § 158 suspension).
  aufhebungsvertrag,

  /// S3 – resignation (12-week blocking period, no severance).
  eigenkuendigung,

  /// S4 – staying employed (reference baseline).
  bleiben,
}

/// Origin of a month's net cashflow (for the UI breakdown/chart).
enum CashflowSource { salary, severance, severanceRefund, alg, gap }

/// A single risk or information flag attached to a scenario. [message] is
/// German UI copy (du-form, no recommendation language, per CLAUDE.md).
class RiskFlag {
  const RiskFlag(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '[$code] $message';
}

/// User profile (spec §6). Cent amounts; German legal terms kept.
class UserProfile {
  const UserProfile({
    required this.birthYear,
    required this.taxClass,
    required this.state,
    this.childAllowanceFactor = 0,
    this.churchMember = false,
    this.kvArt = KvArt.gesetzlich,
    this.healthAdditionalRate,
    this.hasChildForAlg = false,
    this.totalChildren = 0,
    this.childrenUnder25 = 0,
  });

  final int birthYear;
  final TaxClass taxClass;
  final Bundesland state;

  /// Kinderfreibetrag counter for solidarity surcharge / church tax.
  final double childAllowanceFactor;
  final bool churchMember;
  final KvArt kvArt;

  /// GKV additional contribution rate; `null` uses the 2026 average.
  final double? healthAdditionalRate;

  /// Whether a child on the wage tax card raises the ALG rate to 67 %.
  final bool hasChildForAlg;

  /// Children ever had (for the care insurance childless surcharge).
  final int totalChildren;

  /// Children under 25 (for the care insurance discounts).
  final int childrenUnder25;

  int ageInYear(int year) => year - birthYear;
}

/// Employment data (spec §6).
class EmploymentData {
  const EmploymentData({
    required this.grossMonthCents,
    required this.entryDate,
    required this.regularEndDate,
    this.annualExtrasCents = 0,
  });

  /// Monthly gross salary.
  final int grossMonthCents;

  /// Annual special payments (13th salary, bonuses).
  final int annualExtrasCents;

  /// Start of employment (for tenure).
  final DateTime entryDate;

  /// Earliest regular end date honouring the ordinary notice period.
  final DateTime regularEndDate;

  /// Contributory annual gross (salary × 12 + special payments).
  int get grossYearCents => grossMonthCents * 12 + annualExtrasCents;
}

/// Offer / severance data (spec §6).
class OfferData {
  const OfferData({
    required this.severanceGrossCents,
    required this.exitDate,
    this.paidRelease = false,
    this.settlementsCents = 0,
  });

  /// Gross severance pay.
  final int severanceGrossCents;

  /// Exit date per the offer (may be earlier than [EmploymentData.regularEndDate]).
  final DateTime exitDate;

  /// Whether there is a paid release (Freistellung) until the regular end.
  final bool paidRelease;

  /// Gross settlements (remaining holiday, bonus payout).
  final int settlementsCents;
}

/// Result for a single scenario.
class ScenarioResult {
  ScenarioResult({
    required this.type,
    required this.monthlyNetCents,
    required this.monthlySource,
    required this.flags,
  }) : cumulativeNetCents = monthlyNetCents.fold(0, (a, b) => a + b);

  final ScenarioType type;

  /// Net cashflow per month over the horizon (length == horizon).
  final List<int> monthlyNetCents;

  /// Dominant source per month (length == horizon).
  final List<CashflowSource> monthlySource;

  /// Cumulative net over the horizon.
  final int cumulativeNetCents;

  final List<RiskFlag> flags;
}

/// Aggregated result across all four scenarios.
class AggregateResult {
  const AggregateResult({
    required this.horizonMonths,
    required this.referenceDate,
    required this.scenarios,
  });

  final int horizonMonths;
  final DateTime referenceDate;
  final Map<ScenarioType, ScenarioResult> scenarios;

  /// The reference baseline (staying employed).
  ScenarioResult get baseline => scenarios[ScenarioType.bleiben]!;

  /// The scenario with the highest cumulative net over the horizon.
  ScenarioType get bestScenario => scenarios.values
      .reduce((a, b) => b.cumulativeNetCents > a.cumulativeNetCents ? b : a)
      .type;

  /// Difference of a scenario's cumulative net to the baseline (can be
  /// negative).
  int deltaToBaselineCents(ScenarioType type) =>
      scenarios[type]!.cumulativeNetCents - baseline.cumulativeNetCents;
}

int _monthsBetween(DateTime from, DateTime to) =>
    (to.year - from.year) * 12 + (to.month - from.month);

/// Aggregates all four scenarios into monthly net cashflows.
///
/// [referenceDate] anchors month 0 of the horizon (typically "today").
/// [horizonMonths] is the observation window (spec default 24).
AggregateResult aggregateScenarios({
  required UserProfile profile,
  required EmploymentData employment,
  required OfferData offer,
  required DateTime referenceDate,
  int horizonMonths = 24,
  ExitParams? params,
}) {
  final p = params ?? ExitParams.year2026();
  final b = _ScenarioBuilder(
    profile: profile,
    employment: employment,
    offer: offer,
    referenceDate: referenceDate,
    horizon: horizonMonths,
    params: p,
  );

  return AggregateResult(
    horizonMonths: horizonMonths,
    referenceDate: referenceDate,
    scenarios: {
      ScenarioType.bleiben: b.buildStay(),
      ScenarioType.kuendigungAg: b.buildExit(ScenarioType.kuendigungAg),
      ScenarioType.aufhebungsvertrag: b.buildExit(ScenarioType.aufhebungsvertrag),
      ScenarioType.eigenkuendigung: b.buildExit(ScenarioType.eigenkuendigung),
    },
  );
}

/// Internal helper holding the shared derived quantities and building the
/// per-scenario timelines.
class _ScenarioBuilder {
  _ScenarioBuilder({
    required this.profile,
    required this.employment,
    required this.offer,
    required this.referenceDate,
    required this.horizon,
    required this.params,
  }) {
    exitYear = offer.exitDate.year;
    ageAtExit = profile.ageInYear(exitYear);
    grossYear = employment.grossYearCents;

    final net = annualNetIncome(
      grossYearCents: grossYear,
      taxClass: profile.taxClass,
      age: ageAtExit,
      childAllowanceFactor: profile.childAllowanceFactor,
      totalChildren: profile.totalChildren,
      childrenUnder25: profile.childrenUnder25,
      churchMember: profile.churchMember,
      state: profile.state,
      healthAdditionalRate: profile.healthAdditionalRate,
      params: params,
    );
    netSalaryMonth = net.netYearCents ~/ 12;
    taxableSalaryYear = net.taxes.taxableCents;

    final alg = alg1Benefit(
      grossYearCents: grossYear,
      taxClass: profile.taxClass,
      age: ageAtExit,
      hasChild: profile.hasChildForAlg,
      childAllowanceFactor: profile.childAllowanceFactor,
      totalChildren: profile.totalChildren,
      childrenUnder25: profile.childrenUnder25,
      state: profile.state,
      healthAdditionalRate: profile.healthAdditionalRate,
      params: params,
    );
    algMonth = alg.benefitMonthCents;
    algCapped = alg.assessedGrossYearCents < grossYear;

    final tenureMonths = max(0, _monthsBetween(employment.entryDate, offer.exitDate));
    tenureYears = tenureMonths ~/ 12;
    final insuredMonths = min(tenureMonths, 60);
    entitlementMonths =
        alg1EntitlementDays(insuredMonths: insuredMonths, age: ageAtExit, params: params) ~/
            30;

    exitOffset = _clamp(_monthsBetween(referenceDate, offer.exitDate));
  }

  final UserProfile profile;
  final EmploymentData employment;
  final OfferData offer;
  final DateTime referenceDate;
  final int horizon;
  final ExitParams params;

  late final int exitYear;
  late final int ageAtExit;
  late final int grossYear;
  late final int netSalaryMonth;
  late final int taxableSalaryYear;
  late final int algMonth;
  late final bool algCapped;
  late final int tenureYears;
  late final int entitlementMonths;
  late final int exitOffset;

  int _clamp(int offset) => offset.clamp(0, horizon);

  /// S4 – staying employed: salary net every month.
  ScenarioResult buildStay() {
    final net = List<int>.filled(horizon, netSalaryMonth);
    final src = List<CashflowSource>.filled(horizon, CashflowSource.salary);
    return ScenarioResult(
      type: ScenarioType.bleiben,
      monthlyNetCents: net,
      monthlySource: src,
      flags: const [],
    );
  }

  ScenarioResult buildExit(ScenarioType type) {
    final net = List<int>.filled(horizon, 0);
    final src = List<CashflowSource>.filled(horizon, CashflowSource.gap);
    final flags = <RiskFlag>[];

    // 1) Salary until the exit month.
    for (var m = 0; m < exitOffset && m < horizon; m++) {
      net[m] = netSalaryMonth;
      src[m] = CashflowSource.salary;
    }

    // 2) Severance + settlements as a lump in the exit month (S1/S2 only).
    final hasSeverance = type != ScenarioType.eigenkuendigung;
    var blockingMonths = 0;
    var suspensionMonths = 0;

    if (hasSeverance) {
      final sev = severanceComparison(
        taxableIncomeWithoutSeveranceCents: taxableSalaryYear,
        severanceCents: offer.severanceGrossCents,
        splitting: profile.taxClass == TaxClass.iii,
        params: params,
      );
      // Employer withholds regular taxation; the Fünftel saving is
      // refunded later via the tax assessment.
      final severanceNet =
          offer.severanceGrossCents - sev.taxOnSeveranceRegularCents + _settlementsNet();
      if (exitOffset < horizon) {
        net[exitOffset] += severanceNet;
        src[exitOffset] = CashflowSource.severance;
      }
      if (sev.savingsCents > 0) {
        flags.add(RiskFlag(
          'fuenftel_erstattung',
          'Die Steuerersparnis aus der Fünftelregelung von rund '
              '${_euro(sev.savingsCents)} bekommst du erst über die '
              'Steuererklärung im Folgejahr zurück, nicht sofort.',
        ));
        // Refund roughly a year after the exit (next year's assessment).
        final refundOffset = exitOffset + 12;
        if (refundOffset < horizon) {
          net[refundOffset] += sev.savingsCents;
          if (src[refundOffset] == CashflowSource.gap) {
            src[refundOffset] = CashflowSource.severanceRefund;
          }
        }
      }

      // § 158 suspension when the ordinary notice period was shortened.
      suspensionMonths = _suspensionMonths();
      if (suspensionMonths > 0) {
        flags.add(RiskFlag(
          'ruhen_158',
          'Weil das Arbeitsverhältnis vor Ablauf der ordentlichen '
              'Kündigungsfrist endet, ruht dein ALG-Anspruch rund '
              '$suspensionMonths Monat(e) (§ 158 SGB III).',
        ));
      }
    }

    // 3) Blocking period (Sperrzeit).
    if (type == ScenarioType.eigenkuendigung) {
      blockingMonths = _blockingMonths();
      flags.add(const RiskFlag(
        'sperrzeit_eigenkuendigung',
        'Bei einer Eigenkündigung ohne wichtigen Grund verhängt die '
            'Agentur für Arbeit in der Regel eine Sperrzeit von 12 Wochen '
            'und kürzt die Anspruchsdauer um ein Viertel (§ 159 SGB III).',
      ));
    } else if (type == ScenarioType.aufhebungsvertrag) {
      final unlikely = blockingPeriodUnlikely(
        dismissalWasThreatened: true,
        severanceCents: offer.severanceGrossCents,
        grossMonthCents: employment.grossMonthCents,
        tenureYears: tenureYears,
      );
      if (unlikely) {
        flags.add(const RiskFlag(
          'sperrzeit_unwahrscheinlich',
          'Bei einem Aufhebungsvertrag zur Abwendung einer drohenden '
              'betriebsbedingten Kündigung mit maßvoller Abfindung ist eine '
              'Sperrzeit meist unwahrscheinlich – lass das aber im Einzelfall '
              'prüfen.',
        ));
      } else {
        blockingMonths = _blockingMonths();
        flags.add(const RiskFlag(
          'sperrzeit_wahrscheinlich',
          'Ein Aufhebungsvertrag kann eine Sperrzeit von 12 Wochen auslösen '
              '(§ 159 SGB III) und die Anspruchsdauer um ein Viertel kürzen – '
              'lass die Voraussetzungen prüfen.',
        ));
      }
    }

    // 4) ALG phase: starts after the exit, delayed by suspension and/or
    //    blocking period; blocking also shortens the duration by a quarter.
    final algStart = _clamp(exitOffset + max(blockingMonths, suspensionMonths));
    final effectiveMonths =
        blockingMonths > 0 ? (entitlementMonths * 3 + 3) ~/ 4 : entitlementMonths;
    final algEnd = min(algStart + effectiveMonths, horizon);
    for (var m = algStart; m < algEnd; m++) {
      if (src[m] == CashflowSource.gap) {
        net[m] += algMonth;
        src[m] = CashflowSource.alg;
      }
    }

    if (algCapped) {
      flags.add(const RiskFlag(
        'alg_gedeckelt',
        'Dein ALG ist auf die Beitragsbemessungsgrenze gedeckelt – es '
            'bemisst sich nicht nach deinem vollen Gehalt.',
      ));
    }

    // 5) Gap flag: any zero-income month after the exit (health insurance).
    final hasGap = src.skip(exitOffset).any((s) => s == CashflowSource.gap);
    if (hasGap) {
      flags.add(const RiskFlag(
        'kv_luecke',
        'In den Monaten ohne Gehalt und ohne ALG musst du deine '
            'Krankenversicherung selbst klären.',
      ));
    }

    return ScenarioResult(
      type: type,
      monthlyNetCents: net,
      monthlySource: src,
      flags: flags,
    );
  }

  /// Net value of the settlements (holiday/bonus payout), taxed at the
  /// marginal rate on top of the year's salary.
  int _settlementsNet() {
    if (offer.settlementsCents <= 0) return 0;
    final withoutTax =
        incomeTax(taxableIncomeCents: taxableSalaryYear, params: params);
    final withTax = incomeTax(
        taxableIncomeCents: taxableSalaryYear + offer.settlementsCents, params: params);
    return offer.settlementsCents - (withTax - withoutTax);
  }

  int _blockingMonths() {
    final days = params.alg1.blockingPeriodWeeks * 7;
    return (days / 30).round();
  }

  int _suspensionMonths() {
    final missedDays = offer.exitDate.isBefore(employment.regularEndDate)
        ? employment.regularEndDate.difference(offer.exitDate).inDays
        : 0;
    if (missedDays <= 0) return 0;
    final susp = suspension158(
      severanceCents: offer.severanceGrossCents,
      age: ageAtExit,
      tenureYears: tenureYears,
      dailyWageCents: max(1, grossYear ~/ 365),
      missedNoticeDays: missedDays,
      params: params,
    );
    return (susp.suspensionDays / 30).round();
  }

  String _euro(int cents) => '${(cents / 100).round()} €';
}
