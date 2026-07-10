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
import 'm11_buergergeld.dart';
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
enum CashflowSource { salary, severance, severanceRefund, alg, buergergeld, gap }

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
    this.anticipatesOperationalDismissal = false,
  });

  /// Gross severance pay (the negotiated amount of the termination
  /// agreement, S2). The employer-dismissal downside (S1) carries no
  /// severance.
  final int severanceGrossCents;

  /// Exit date per the offer (may be earlier than [EmploymentData.regularEndDate]).
  final DateTime exitDate;

  /// Whether there is a paid release (Freistellung) until the regular end.
  final bool paidRelease;

  /// Gross settlements (remaining holiday, bonus payout).
  final int settlementsCents;

  /// Whether the termination agreement documents that it anticipates a
  /// lawful **operational** (betriebsbedingt) employer dismissal. Together
  /// with an observed notice period and a § 1a-conforming severance this is
  /// a *wichtiger Grund* that avoids the ALG blocking period (§ 159 SGB III).
  final bool anticipatesOperationalDismissal;
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

  /// The best **actionable** exit scenario over the horizon, i.e. the one
  /// with the highest cumulative net among S1–S3. Staying employed
  /// ([ScenarioType.bleiben]) is the reference baseline, not a choice on
  /// the table when a termination is already on the horizon, so it never
  /// wins the "best" star (it would trivially always win on full salary).
  ScenarioType get bestScenario => scenarios.values
      .where((s) => s.type != ScenarioType.bleiben)
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
/// When [includeBuergergeld] is set (with household finances via
/// [startingAssetsCents] / [monthlyExpensesCents]), a means-tested Bürgergeld
/// floor is modelled for the exit scenarios once assets are spent down to the
/// statutory allowance (M11).
AggregateResult aggregateScenarios({
  required UserProfile profile,
  required EmploymentData employment,
  required OfferData offer,
  required DateTime referenceDate,
  int horizonMonths = 24,
  ExitParams? params,
  bool includeBuergergeld = false,
  int startingAssetsCents = 0,
  int monthlyExpensesCents = 0,
  int kduMonthlyCents = 0,
  int householdSize = 1,
  BuergergeldParams? buergergeld,
}) {
  final p = params ?? ExitParams.year2026();
  final b = _ScenarioBuilder(
    profile: profile,
    employment: employment,
    offer: offer,
    referenceDate: referenceDate,
    horizon: horizonMonths,
    params: p,
    includeBuergergeld: includeBuergergeld,
    startingAssetsCents: startingAssetsCents,
    monthlyExpensesCents: monthlyExpensesCents,
    kduMonthlyCents: kduMonthlyCents,
    householdSize: householdSize,
    buergergeld: buergergeld ?? BuergergeldParams.year2026(),
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
    required this.includeBuergergeld,
    required this.startingAssetsCents,
    required this.monthlyExpensesCents,
    required this.kduMonthlyCents,
    required this.householdSize,
    required this.buergergeld,
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
    regularEndOffset = _clamp(_monthsBetween(referenceDate, employment.regularEndDate));
  }

  final UserProfile profile;
  final EmploymentData employment;
  final OfferData offer;
  final DateTime referenceDate;
  final int horizon;
  final ExitParams params;
  final bool includeBuergergeld;
  final int startingAssetsCents;
  final int monthlyExpensesCents;
  final int kduMonthlyCents;
  final int householdSize;
  final BuergergeldParams buergergeld;

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
  late final int regularEndOffset;

  int _clamp(int offset) => offset.clamp(0, horizon);

  /// Calendar month for a horizon offset (month 0 == [referenceDate]).
  DateTime _monthAt(int offset) =>
      DateTime(referenceDate.year, referenceDate.month + offset);

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

    // When the employment actually ends (salary stops) depends on the
    // scenario:
    //  * S1 employer dismissal – the employer must observe the ordinary
    //    notice period, so salary runs to the regular end date;
    //  * S2 termination agreement – to the agreed exit date, or to the
    //    regular end when a paid release (Freistellung) was agreed;
    //  * S3 resignation – to the chosen exit date.
    final usePaidRelease =
        offer.paidRelease && type == ScenarioType.aufhebungsvertrag;
    final int endOffset;
    switch (type) {
      case ScenarioType.kuendigungAg:
        endOffset = regularEndOffset;
      case ScenarioType.aufhebungsvertrag:
        endOffset = usePaidRelease ? regularEndOffset : exitOffset;
      case ScenarioType.eigenkuendigung:
        endOffset = exitOffset;
      case ScenarioType.bleiben:
        endOffset = horizon;
    }

    // 1) Salary until the employment actually ends.
    for (var m = 0; m < endOffset && m < horizon; m++) {
      net[m] = netSalaryMonth;
      src[m] = CashflowSource.salary;
    }
    if (usePaidRelease && regularEndOffset > exitOffset) {
      flags.add(const RiskFlag(
        'freistellung',
        'Während der bezahlten Freistellung läuft dein Gehalt bis zum '
            'regulären Ende weiter; das ALG beginnt erst danach.',
      ));
    }

    // 2) ALG timing. The § 158 suspension (severance + shortened notice) and
    //    the § 159 blocking period both push the ALG start out; the blocking
    //    period also shortens the entitlement by a quarter. Determined before
    //    the severance so its same-year ALG (Progressionsvorbehalt) is known.
    final hasSeverance = type == ScenarioType.aufhebungsvertrag;
    var blockingMonths = 0;
    final suspensionMonths =
        (hasSeverance && !usePaidRelease) ? _suspensionMonths() : 0;
    if (suspensionMonths > 0) {
      flags.add(RiskFlag(
        'ruhen_158',
        'Weil das Arbeitsverhältnis vor Ablauf der ordentlichen '
            'Kündigungsfrist endet, ruht dein ALG-Anspruch rund '
            '$suspensionMonths Monat(e) (§ 158 SGB III).',
      ));
    }

    switch (type) {
      case ScenarioType.eigenkuendigung:
        blockingMonths = _blockingMonths();
        flags.add(const RiskFlag(
          'sperrzeit_eigenkuendigung',
          'Bei einer Eigenkündigung ohne wichtigen Grund verhängt die '
              'Agentur für Arbeit in der Regel eine Sperrzeit von 12 Wochen '
              'und kürzt die Anspruchsdauer um ein Viertel (§ 159 SGB III).',
        ));
      case ScenarioType.aufhebungsvertrag:
        final noticeObserved = usePaidRelease ||
            !offer.exitDate.isBefore(employment.regularEndDate);
        // Safe harbour: anticipated dismissal + notice observed + severance
        // within the § 1a corridor (0.25–0.5 salaries/year).
        final safeHarbour = blockingPeriodUnlikely(
          dismissalWasThreatened: offer.anticipatesOperationalDismissal,
          noticePeriodObserved: noticeObserved,
          severanceCents: offer.severanceGrossCents,
          grossMonthCents: employment.grossMonthCents,
          tenureYears: tenureYears,
        );
        // A genuinely threatened, lawful operational dismissal with the notice
        // period observed is itself the "wichtiger Grund" – then a Sperrzeit is
        // not to be expected even when the severance exceeds the corridor (BA
        // Weisungen zu § 159; e.g. IG-BCE social plans with a factor of 1.0+).
        final threatenedWithNotice =
            offer.anticipatesOperationalDismissal && noticeObserved;
        if (safeHarbour) {
          flags.add(const RiskFlag(
            'sperrzeit_unwahrscheinlich',
            'Weil der Aufhebungsvertrag eine drohende betriebsbedingte '
                'Kündigung vorwegnimmt, die Kündigungsfrist gewahrt ist und '
                'die Abfindung im Rahmen (0,25–0,5 Monatsgehälter je Jahr) '
                'bleibt, ist eine Sperrzeit meist unwahrscheinlich – lass es '
                'aber im Einzelfall prüfen (§ 159 SGB III).',
          ));
        } else if (threatenedWithNotice) {
          flags.add(const RiskFlag(
            'sperrzeit_unwahrscheinlich_pruefung',
            'Weil eine betriebsbedingte Kündigung drohte und die '
                'Kündigungsfrist gewahrt ist, ist eine Sperrzeit auch bei '
                'höherer Abfindung meist nicht zu erwarten. Weil die Abfindung '
                'über 0,5 Monatsgehältern je Jahr liegt, prüft die Agentur '
                'gegebenenfalls noch, ob die Kündigung sozial gerechtfertigt '
                'gewesen wäre – lass es im Einzelfall prüfen (§ 159 SGB III).',
          ));
        } else {
          blockingMonths = _blockingMonths();
          flags.add(const RiskFlag(
            'sperrzeit_wahrscheinlich',
            'Für diesen Aufhebungsvertrag sind die Voraussetzungen für den '
                'Wegfall der Sperrzeit nicht erfüllt (keine vorweggenommene '
                'betriebsbedingte Kündigung oder die Kündigungsfrist ist nicht '
                'gewahrt). Dann drohen 12 Wochen Sperrzeit und ein Viertel '
                'weniger Anspruchsdauer (§ 159 SGB III) – lass die '
                'Voraussetzungen prüfen.',
          ));
        }
      case ScenarioType.kuendigungAg:
        flags.add(const RiskFlag(
          'kuendigung_ag_downside',
          'Die Rückfallebene: Wenn du nicht unterschreibst und der '
              'Arbeitgeber (betriebsbedingt) kündigt, bekommst du Gehalt bis '
              'zum Ende der Kündigungsfrist und danach ALG 1 – ohne Abfindung, '
              'aber ohne Sperrzeit. Eine Abfindung gäbe es hier nur über eine '
              'Kündigungsschutzklage bzw. einen Vergleich.',
        ));
      case ScenarioType.bleiben:
        break;
    }

    final algStart = _clamp(endOffset + max(blockingMonths, suspensionMonths));
    final effectiveMonths =
        blockingMonths > 0 ? (entitlementMonths * 3 + 3) ~/ 4 : entitlementMonths;
    final algEnd = min(algStart + effectiveMonths, horizon);

    // 3) Severance + settlements as a lump when the employment ends. Only the
    //    termination agreement (S2) carries the negotiated severance; the
    //    employer-dismissal downside (S1) and a resignation (S3) do not.
    if (hasSeverance) {
      // § 32b: ALG received in the same calendar year as the severance payout
      // is tax-free but raises the tax rate on the severance.
      final severanceYear = _monthAt(endOffset).year;
      var algProgressionCents = 0;
      for (var m = algStart; m < algEnd; m++) {
        if (m != endOffset && _monthAt(m).year == severanceYear) {
          algProgressionCents += algMonth;
        }
      }
      final sev = severanceComparison(
        taxableIncomeWithoutSeveranceCents: taxableSalaryYear,
        severanceCents: offer.severanceGrossCents,
        splitting: profile.taxClass == TaxClass.iii,
        progressionIncomeCents: algProgressionCents,
        params: params,
      );
      // Employer withholds regular taxation; the Fünftel saving is refunded
      // later via the tax assessment.
      final severanceNet =
          offer.severanceGrossCents - sev.taxOnSeveranceRegularCents + _settlementsNet();
      if (endOffset < horizon) {
        net[endOffset] += severanceNet;
        src[endOffset] = CashflowSource.severance;
      }
      if (algProgressionCents > 0) {
        flags.add(RiskFlag(
          'progressionsvorbehalt',
          'Das im Jahr $severanceYear bezogene ALG (rund '
              '${_euro(algProgressionCents)}) ist steuerfrei, hebt aber über '
              'den Progressionsvorbehalt (§ 32b EStG) deinen Steuersatz – auch '
              'auf die Abfindung. Das ist hier bereits eingerechnet.',
        ));
      }
      if (sev.savingsCents > 0) {
        flags.add(RiskFlag(
          'fuenftel_erstattung',
          'Die Steuerersparnis aus der Fünftelregelung von rund '
              '${_euro(sev.savingsCents)} bekommst du erst über die '
              'Steuererklärung im Folgejahr zurück, nicht sofort.',
        ));
        // Refund roughly a year after the exit (next year's assessment).
        final refundOffset = endOffset + 12;
        if (refundOffset < horizon) {
          net[refundOffset] += sev.savingsCents;
          if (src[refundOffset] == CashflowSource.gap) {
            src[refundOffset] = CashflowSource.severanceRefund;
          }
        }
      }
    }

    // 4) Lay out the ALG phase (skips months already filled by salary or the
    //    severance lump).
    for (var m = algStart; m < algEnd; m++) {
      if (src[m] == CashflowSource.gap) {
        net[m] += algMonth;
        src[m] = CashflowSource.alg;
      }
    }

    // 5) Bürgergeld (SGB II) means-tested floor: after ALG ends, once usable
    //    assets are spent down to the statutory allowance (Karenzzeit: higher
    //    allowance in the first year of receipt), a benefit covers part of the
    //    remaining gap. Simulates the asset draw-down over the horizon.
    if (includeBuergergeld && monthlyExpensesCents > 0) {
      final benefit = buergergeld.monthlyBenefitCents(kduMonthlyCents: kduMonthlyCents);
      var assets = startingAssetsCents;
      var monthsReceived = 0;
      var everReceived = false;
      for (var m = 0; m < horizon; m++) {
        if (src[m] == CashflowSource.gap) {
          final allowance = buergergeld.assetAllowanceCents(
              monthsReceived: monthsReceived, householdSize: householdSize);
          if (assets <= allowance) {
            net[m] += benefit;
            src[m] = CashflowSource.buergergeld;
            monthsReceived++;
            everReceived = true;
          }
        }
        assets += net[m] - monthlyExpensesCents;
        if (assets < 0) assets = 0;
      }
      if (everReceived) {
        flags.add(RiskFlag(
          'buergergeld',
          'Nach dem ALG 1 kann im Betrachtungszeitraum Bürgergeld (SGB II) '
              'greifen – aber erst, wenn dein Vermögen bis auf den Freibetrag '
              'aufgebraucht ist (Karenzzeit im 1. Jahr rund '
              '${_euro(buergergeld.assetAllowanceInKarenzCents)}, danach rund '
              '${_euro(buergergeld.assetAllowanceAfterKarenzCents)} je Person). '
              'Angesetzt ist der Regelsatz'
              '${kduMonthlyCents > 0 ? ' plus Miete' : ' (Miete/Unterkunft käme obendrauf)'}'
              ' – eine grobe Schätzung.',
        ));
      }
    }

    if (algCapped) {
      flags.add(const RiskFlag(
        'alg_gedeckelt',
        'Dein ALG ist auf die Beitragsbemessungsgrenze gedeckelt – es '
            'bemisst sich nicht nach deinem vollen Gehalt.',
      ));
    }

    // 5) Gap flag: any zero-income month after the employment ends
    //    (health insurance).
    final hasGap = src.skip(endOffset).any((s) => s == CashflowSource.gap);
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
