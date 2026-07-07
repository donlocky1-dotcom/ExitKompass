/// M10 – Remaining-vacation compensation (Urlaubsabgeltung, § 7 Abs. 4 BUrlG).
///
/// When the employment ends and vacation can no longer be taken, the open
/// days must be paid out. The value of a vacation day follows the average
/// earnings of the last 13 weeks (§ 11 BUrlG); assuming a constant monthly
/// salary this is:
///
/// ```text
/// daily value = monthly gross × 3  /  (13 × working days per week)
/// ```
///
/// This module also offers the pro-rata entitlement for a partial year of
/// employment (§ 5 BUrlG). Orientation only – open days, variable pay and
/// contractual/collective extra vacation should be checked individually.
/// All amounts are `int` cents.
library;

/// Result of the vacation compensation calculation (all amounts in cents).
class VacationCompensation {
  const VacationCompensation({
    required this.dailyValueCents,
    required this.remainingDays,
    required this.totalCents,
    required this.workDaysPerWeek,
  });

  /// Gross value of one vacation day.
  final int dailyValueCents;

  /// Open vacation days paid out (input).
  final int remainingDays;

  /// Total compensation = [dailyValueCents] × [remainingDays].
  final int totalCents;

  final int workDaysPerWeek;
}

/// Computes the Urlaubsabgeltung for [remainingDays] open vacation days.
///
/// [monthlyGrossCents]: gross monthly salary. [workDaysPerWeek]: contractual
/// working days per week (usually 5).
VacationCompensation vacationCompensation({
  required int monthlyGrossCents,
  required int remainingDays,
  int workDaysPerWeek = 5,
}) {
  assert(monthlyGrossCents >= 0);
  assert(remainingDays >= 0);
  assert(workDaysPerWeek >= 1 && workDaysPerWeek <= 7);

  final daily = (monthlyGrossCents * 3 / (13 * workDaysPerWeek)).round();
  return VacationCompensation(
    dailyValueCents: daily,
    remainingDays: remainingDays,
    totalCents: daily * remainingDays,
    workDaysPerWeek: workDaysPerWeek,
  );
}

/// Pro-rata vacation entitlement for a partial year (§ 5 BUrlG): full-year
/// entitlement × months employed ÷ 12. Fractions of at least half a day are
/// rounded up (§ 5 Abs. 2 BUrlG).
int proRataVacationDays({
  required int fullYearDays,
  required int monthsEmployed,
}) {
  assert(fullYearDays >= 0);
  final months = monthsEmployed.clamp(0, 12);
  return (fullYearDays * months / 12).round();
}
