/// M11 – Basic income support (Bürgergeld / SGB II) as a means-tested floor
/// after ALG 1 runs out.
///
/// Within the 24–36 month horizon many people exhaust ALG 1 and only then
/// face the question of Bürgergeld. Unlike ALG 1 it is **means-tested**: it
/// is paid only once usable assets have been spent down to the statutory
/// allowance (§ 12 SGB II). During the first year of receipt a **Karenzzeit**
/// applies with a much higher allowance (§ 12 Abs. 3 SGB II).
///
/// This module provides the 2026 parameters and the per-month allowance; the
/// asset draw-down over the horizon is simulated by the scenario aggregator
/// (M5). All amounts are `int` cents. The result is an **estimate**: the
/// actual Regelbedarf depends on the household, and the Kosten der Unterkunft
/// (rent, KdU) are paid on top and are not part of this floor unless supplied.
library;

/// Parameters of the Bürgergeld means test (SGB II).
class BuergergeldParams {
  const BuergergeldParams({
    required this.regelsatzSingleMonthlyCents,
    required this.assetAllowanceInKarenzCents,
    required this.assetAllowanceAfterKarenzCents,
    required this.karenzMonths,
  });

  /// Standard requirement (Regelbedarf) for a single adult, per month
  /// (§ 20 SGB II). KdU (rent) is paid on top and not included here.
  final int regelsatzSingleMonthlyCents;

  /// "Erhebliches Vermögen" allowance for the first person during the
  /// Karenzzeit (§ 12 Abs. 3 SGB II).
  final int assetAllowanceInKarenzCents;

  /// Ordinary asset allowance per person after the Karenzzeit
  /// (§ 12 Abs. 2 SGB II, Regelfall).
  final int assetAllowanceAfterKarenzCents;

  /// Length of the Karenzzeit in months of Bürgergeld receipt.
  final int karenzMonths;

  /// 2026 values (Regelbedarf fortgeschrieben / Nullrunde; see ASSUMPTIONS
  /// A20). Amounts in cents.
  factory BuergergeldParams.year2026() => const BuergergeldParams(
        regelsatzSingleMonthlyCents: 56300, // 563 € (§ 20 SGB II, 2026)
        assetAllowanceInKarenzCents: 4000000, // 40.000 € erste Person
        assetAllowanceAfterKarenzCents: 1500000, // 15.000 € je Person
        karenzMonths: 12,
      );

  /// Usable-asset allowance depending on how many months of Bürgergeld have
  /// already been received. During the Karenzzeit the (higher) allowance of
  /// the first person applies; afterwards the ordinary per-person allowance,
  /// scaled by [householdSize].
  int assetAllowanceCents({
    required int monthsReceived,
    int householdSize = 1,
  }) {
    final size = householdSize < 1 ? 1 : householdSize;
    if (monthsReceived < karenzMonths) {
      // First person the Karenzzeit allowance, each further person the
      // ordinary allowance (§ 12 Abs. 3 S. 2 SGB II).
      return assetAllowanceInKarenzCents +
          (size - 1) * assetAllowanceAfterKarenzCents;
    }
    return size * assetAllowanceAfterKarenzCents;
  }

  /// Monthly Bürgergeld inflow modelled as the standard requirement plus the
  /// (optional) housing costs [kduMonthlyCents].
  int monthlyBenefitCents({int kduMonthlyCents = 0}) =>
      regelsatzSingleMonthlyCents + (kduMonthlyCents < 0 ? 0 : kduMonthlyCents);
}
