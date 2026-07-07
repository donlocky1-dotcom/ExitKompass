/// M9 – Post-contractual non-compete compensation (Karenzentschädigung,
/// §§ 74 ff. HGB).
///
/// A post-contractual non-compete clause (nachvertragliches Wettbewerbsverbot)
/// is only binding if the employer commits to pay, for the duration of the
/// ban, a compensation of **at least half** of the employee's last
/// contractual benefits (§ 74 Abs. 2 HGB). The ban may last **at most two
/// years** (§ 74a Abs. 1 S. 3 HGB). Other income earned during the ban is
/// credited against the compensation, but only to the extent that
/// compensation + other income exceeds **110 %** of the last benefits – or
/// **125 %** if the ban forced the employee to relocate (§ 74c HGB).
///
/// Orientation only; the definition of "vertragsmäßige Leistungen" (base pay
/// plus regular variable parts, benefits in kind, …) and borderline cases
/// should be checked by a specialist lawyer. All amounts are `int` cents.
library;

/// Maximum binding duration of a non-compete (§ 74a Abs. 1 S. 3 HGB).
const int maxNonCompeteMonths = 24;

/// Result of the Karenzentschädigung calculation (all amounts in cents).
class NonCompeteResult {
  const NonCompeteResult({
    required this.minMonthlyCompensationCents,
    required this.creditPerMonthCents,
    required this.monthlyCompensationAfterCreditCents,
    required this.totalCompensationCents,
    required this.totalAfterCreditCents,
    required this.creditThresholdMonthlyCents,
    required this.durationMonths,
    required this.exceedsMaxDuration,
  });

  /// Statutory minimum per month: 50 % of the last contractual benefits
  /// (§ 74 Abs. 2 HGB).
  final int minMonthlyCompensationCents;

  /// Amount credited per month under § 74c (other income above the
  /// 110 %/125 % threshold).
  final int creditPerMonthCents;

  /// Monthly compensation actually payable after the § 74c credit.
  final int monthlyCompensationAfterCreditCents;

  /// Minimum compensation over the whole duration (before crediting).
  final int totalCompensationCents;

  /// Compensation over the whole duration after the § 74c credit.
  final int totalAfterCreditCents;

  /// The 110 %/125 % threshold (per month) used for the § 74c credit.
  final int creditThresholdMonthlyCents;

  /// Duration of the ban in months (as entered).
  final int durationMonths;

  /// Whether the entered duration exceeds the two-year statutory maximum.
  final bool exceedsMaxDuration;

  /// Whether other income reduced the compensation.
  bool get reducedByCredit => creditPerMonthCents > 0;
}

/// Computes the Karenzentschädigung for a non-compete.
///
/// [lastMonthlyBenefitsCents]: last contractual benefits per month (gross).
/// [durationMonths]: agreed duration of the ban. [otherMonthlyIncomeCents]:
/// other income earned per month during the ban (§ 74c). [relocationForced]:
/// whether the ban forced a change of residence (raises the credit threshold
/// from 110 % to 125 %).
NonCompeteResult nonCompeteCompensation({
  required int lastMonthlyBenefitsCents,
  required int durationMonths,
  int otherMonthlyIncomeCents = 0,
  bool relocationForced = false,
}) {
  assert(lastMonthlyBenefitsCents >= 0);
  assert(durationMonths >= 0);
  assert(otherMonthlyIncomeCents >= 0);

  final minMonthly = (lastMonthlyBenefitsCents / 2).round();
  final thresholdPercent = relocationForced ? 125 : 110;
  final threshold = (lastMonthlyBenefitsCents * thresholdPercent / 100).round();

  // § 74c: credit only the part by which (compensation + other income)
  // exceeds the threshold, and never more than the compensation itself.
  final excess = minMonthly + otherMonthlyIncomeCents - threshold;
  final credit = excess <= 0 ? 0 : (excess > minMonthly ? minMonthly : excess);
  final afterCredit = minMonthly - credit;

  return NonCompeteResult(
    minMonthlyCompensationCents: minMonthly,
    creditPerMonthCents: credit,
    monthlyCompensationAfterCreditCents: afterCredit,
    totalCompensationCents: minMonthly * durationMonths,
    totalAfterCreditCents: afterCredit * durationMonths,
    creditThresholdMonthlyCents: threshold,
    durationMonths: durationMonths,
    exceedsMaxDuration: durationMonths > maxNonCompeteMonths,
  );
}
