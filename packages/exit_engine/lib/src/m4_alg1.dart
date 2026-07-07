/// M4 – Unemployment benefit ALG 1 (SGB III).
///
/// * Assessment wage (Bemessungsentgelt) from the contributory annual
///   gross, capped at the pension/unemployment ceiling (§§ 151, 152
///   SGB III),
/// * flat-rate net benefit wage (Leistungsentgelt): deduction of a 20 %
///   social insurance lump sum, notional wage tax and solidarity
///   surcharge (§ 153 SGB III),
/// * benefit rate 60 % / 67 % with child (§ 149 SGB III),
/// * monthly amount = 30 daily rates (§ 154 SGB III),
/// * entitlement duration by age and insured months (§ 147 SGB III),
/// * blocking period (Sperrzeit) for giving up a job: 12 weeks plus a
///   reduction of the entitlement duration by at least one quarter
///   (§ 159, § 148 Abs. 1 Nr. 4), including the spec §5 heuristic for
///   termination agreements signed to avoid an operational dismissal,
/// * benefit suspension on severance pay with a shortened notice period
///   (Ruhen, § 158 SGB III).
library;

import 'dart:math';

import 'm1_income_tax.dart';
import 'money.dart';
import 'params.dart';

/// ALG 1 benefit assessment (all amounts in cents).
class Alg1Assessment {
  const Alg1Assessment({
    required this.assessedGrossYearCents,
    required this.assessedGrossDayCents,
    required this.socialLumpYearCents,
    required this.wageTaxYearCents,
    required this.soliYearCents,
    required this.benefitBaseDayCents,
    required this.benefitRate,
    required this.benefitDayCents,
  });

  /// Capped contributory annual wage (assessment basis).
  final int assessedGrossYearCents;

  /// Daily assessment wage (annual wage / 365).
  final int assessedGrossDayCents;

  /// Social insurance lump sum: 20 % of the assessment wage (per year).
  final int socialLumpYearCents;

  /// Notional annual wage tax on the assessment wage.
  final int wageTaxYearCents;

  /// Notional solidarity surcharge on that wage tax.
  final int soliYearCents;

  /// Flat-rate net wage per day (Leistungsentgelt, § 153 SGB III).
  final int benefitBaseDayCents;

  /// 0.60 (general) or 0.67 (with child).
  final double benefitRate;

  /// Daily ALG 1 benefit.
  final int benefitDayCents;

  /// Monthly amount: 30 daily rates (§ 154 SGB III).
  int get benefitMonthCents => 30 * benefitDayCents;
}

/// Computes the daily and monthly ALG 1 benefit.
///
/// [grossYearCents]: contributory wage of the last 12 months (assessment
/// period). The tax class / children parameters control the notional
/// wage tax per § 153 SGB III; [hasChild] switches to the increased
/// benefit rate of 67 %.
Alg1Assessment alg1Benefit({
  required int grossYearCents,
  required TaxClass taxClass,
  required int age,
  bool hasChild = false,
  double childAllowanceFactor = 0,
  int totalChildren = 0,
  int childrenUnder25 = 0,
  Bundesland state = Bundesland.nordrheinWestfalen,
  double? healthAdditionalRate,
  ExitParams? params,
}) {
  assert(grossYearCents >= 0);
  final p = params ?? ExitParams.year2026();
  final a = p.alg1;

  // §§ 151/152: assessment wage, capped at the pension/unemployment
  // ceiling.
  final assessedYear = min(grossYearCents, p.socialInsurance.ceilingPensionUnempYearCents);
  final assessedDay = assessedYear ~/ a.daysPerYear;

  // § 153 Abs. 1: deductions from the assessment wage.
  final socialLump = rateFloor(assessedYear, a.socialSecurityLumpRate);
  final taxes = annualWageTax(
    grossYearCents: assessedYear,
    taxClass: taxClass,
    age: age,
    childAllowanceFactor: childAllowanceFactor,
    totalChildren: totalChildren,
    childrenUnder25: childrenUnder25,
    // Church tax has not been deducted since 2005 (§ 153 SGB III).
    churchMember: false,
    state: state,
    healthAdditionalRate: healthAdditionalRate,
    params: p,
  );

  final benefitBaseYear =
      max(0, assessedYear - socialLump - taxes.wageTaxCents - taxes.soliCents);
  final benefitBaseDay = benefitBaseYear ~/ a.daysPerYear;

  final rate = hasChild ? a.benefitRateWithChild : a.benefitRateGeneral;
  final benefitDay = rateFloor(benefitBaseDay, rate);

  return Alg1Assessment(
    assessedGrossYearCents: assessedYear,
    assessedGrossDayCents: assessedDay,
    socialLumpYearCents: socialLump,
    wageTaxYearCents: taxes.wageTaxCents,
    soliYearCents: taxes.soliCents,
    benefitBaseDayCents: benefitBaseDay,
    benefitRate: rate,
    benefitDayCents: benefitDay,
  );
}

/// Entitlement duration in benefit days per § 147 Abs. 2 SGB III
/// (30 days = 1 month).
///
/// [insuredMonths]: months of compulsory insurance within the extended
/// 5-year framework period. Returns 0 when the 12-month qualifying
/// period is not met.
int alg1EntitlementDays({
  required int insuredMonths,
  required int age,
  ExitParams? params,
}) {
  final p = params ?? ExitParams.year2026();
  var days = 0;
  for (final row in p.alg1.durationTable) {
    if (insuredMonths >= row.minInsuredMonths && age >= row.minAge) {
      days = max(days, row.entitlementDays);
    }
  }
  return days;
}

/// Effects of a blocking period (Sperrzeit) for giving up a job
/// (§ 159 Abs. 1 S. 2 Nr. 1 SGB III), e.g. resignation or termination
/// agreement without good cause.
class BlockingPeriodResult {
  const BlockingPeriodResult({
    required this.blockingDays,
    required this.reductionDays,
    required this.entitlementBeforeDays,
    required this.benefitDayCents,
  });

  /// Length of the blocking period (regular case 12 weeks = 84 days);
  /// no benefit is paid during it and the benefit start is postponed.
  final int blockingDays;

  /// Reduction of the entitlement duration: the blocking period days,
  /// but at least one quarter of the entitlement for a 12-week blocking
  /// period (§ 148 Abs. 1 Nr. 4 SGB III).
  final int reductionDays;

  /// Original entitlement duration.
  final int entitlementBeforeDays;

  /// Daily benefit rate (to value the loss).
  final int benefitDayCents;

  /// Remaining entitlement after the reduction.
  int get remainingEntitlementDays => max(0, entitlementBeforeDays - reductionDays);

  /// Benefit permanently lost through the entitlement reduction.
  int get lostBenefitCents => min(reductionDays, entitlementBeforeDays) * benefitDayCents;
}

/// Simulates a 12-week blocking period for giving up a job.
BlockingPeriodResult blockingPeriodSimulation({
  required int entitlementDays,
  required int benefitDayCents,
  ExitParams? params,
}) {
  final p = params ?? ExitParams.year2026();
  final a = p.alg1;
  final blockingDays = a.blockingPeriodWeeks * 7;
  final quarter = rateFloor(entitlementDays, a.blockingPeriodMinReductionShare);
  return BlockingPeriodResult(
    blockingDays: blockingDays,
    reductionDays: max(blockingDays, quarter),
    entitlementBeforeDays: entitlementDays,
    benefitDayCents: benefitDayCents,
  );
}

/// Heuristic of spec §5 (M4): a termination agreement concluded to avert
/// a concretely threatened, lawful **operational** (betriebsbedingt)
/// dismissal does as a rule NOT trigger a blocking period when
/// (Fachliche Weisungen of the BA to § 159 SGB III, Ziff. 159.1.2.1.1):
///
/// * the employer would otherwise have terminated for operational reasons
///   ([dismissalWasThreatened]),
/// * the ordinary notice period is observed ([noticePeriodObserved]), and
/// * the severance stays within the § 1a-KSchG corridor of 0.25–0.5 gross
///   monthly salaries per year of tenure.
///
/// A severance **above** 0.5 does not automatically cause a blocking
/// period (it may still be accepted if the dismissal would have been
/// socially justified), but the safe harbour is left, so the heuristic
/// returns `false` there. A very small or zero severance stays inside the
/// safe harbour (there is no lower bar for avoiding the blocking period).
///
/// Returns `true` when a blocking period is unlikely. This is a
/// heuristic, not a guarantee — the UI must always add a
/// "have it checked" notice.
bool blockingPeriodUnlikely({
  required bool dismissalWasThreatened,
  required bool noticePeriodObserved,
  required int severanceCents,
  required int grossMonthCents,
  required int tenureYears,
}) {
  if (!dismissalWasThreatened || !noticePeriodObserved) return false;
  if (tenureYears <= 0 || grossMonthCents <= 0) return false;
  // Upper edge of the § 1a corridor: 0.5 monthly salaries per year of
  // tenure, computed in exact cents.
  final maxSeverance = grossMonthCents * tenureYears ~/ 2;
  return severanceCents <= maxSeverance;
}

/// Benefit suspension on severance pay (Ruhen, § 158 SGB III).
class Suspension158Result {
  const Suspension158Result({
    required this.applicableShare,
    required this.severanceShareCents,
    required this.suspensionDaysUncapped,
    required this.suspensionDays,
  });

  /// Share of the severance taken into account (0.25–0.60).
  final double applicableShare;

  /// Portion of the severance that counts as wage.
  final int severanceShareCents;

  /// Suspension days from the severance share alone (before caps).
  final int suspensionDaysUncapped;

  /// Effective suspension days after all caps (notice period, 1 year,
  /// severance consumption). No benefit is paid during the suspension,
  /// but the entitlement duration is preserved (no § 148 reduction).
  final int suspensionDays;
}

/// Checks the suspension per § 158 SGB III: the employment ended without
/// observing the ordinary notice period and the employee receives a
/// severance.
///
/// [missedNoticeDays]: days between the actual end of employment and the
/// day the ordinary notice period would have ended (0 = notice period
/// observed, no suspension).
/// [dailyWageCents]: last earned wage per calendar day (uncapped annual
/// gross / 365).
Suspension158Result suspension158({
  required int severanceCents,
  required int age,
  required int tenureYears,
  required int dailyWageCents,
  required int missedNoticeDays,
  ExitParams? params,
}) {
  assert(severanceCents >= 0);
  assert(dailyWageCents > 0);
  final p = params ?? ExitParams.year2026();
  final r = p.alg1.suspension158;

  // Integer percentage points so that e.g. 60 % − 2×5 % − 1×5 % yields
  // exactly 45 % (no floating-point drift).
  var sharePct = (r.baseShare * 100).round() -
      (tenureYears ~/ 5) * (r.reductionPer5YearsTenure * 100).round() -
      (max(0, age - r.ageThreshold) ~/ 5) * (r.reductionPer5YearsAge * 100).round();
  sharePct = max(sharePct, (r.minShare * 100).round());

  final severanceShare = (severanceCents * sharePct) ~/ 100;
  final daysFromSeverance = severanceShare ~/ dailyWageCents;

  final suspensionDays = [
    daysFromSeverance,
    max(0, missedNoticeDays),
    r.maxSuspensionDays,
  ].reduce(min);

  return Suspension158Result(
    applicableShare: sharePct / 100,
    severanceShareCents: severanceShare,
    suspensionDaysUncapped: daysFromSeverance,
    suspensionDays: missedNoticeDays <= 0 ? 0 : suspensionDays,
  );
}
