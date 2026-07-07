/// M3 – Severance pay: regular taxation vs. Fünftelregelung
/// (§ 34 Abs. 1 EStG).
///
/// Compares the income tax on a taxable income plus severance under
/// regular taxation with the reduced taxation under the
/// Fünftelregelung (one-fifth rule):
///
/// ```text
/// tax_reduced = tax(zvE_rest) + 5 × ( tax(zvE_rest + severance/5) − tax(zvE_rest) )
/// ```
///
/// Since assessment year 2025 employers no longer apply the
/// Fünftelregelung in wage tax withholding (Wachstumschancengesetz,
/// repeal of § 39b Abs. 3 S. 9–10 EStG); the relief is only granted via
/// the income tax return. The result flag
/// [SeveranceTaxResult.refundOnlyViaTaxReturn] makes this explicit.
///
/// The engine also offers a rough plausibility check for the
/// "Zusammenballung von Einkünften" (income bunching) requirement of
/// § 34 EStG (spec §5, M3): the one-fifth rule only applies when the
/// severance plus the income earned in the payout year exceeds the
/// income the employee would have earned without the termination.
library;

import 'dart:math';

import 'm1_income_tax.dart';
import 'params.dart';

/// Result of the severance tax comparison (all amounts in cents).
class SeveranceTaxResult {
  const SeveranceTaxResult({
    required this.taxableIncomeWithoutSeveranceCents,
    required this.severanceCents,
    required this.taxWithoutSeveranceCents,
    required this.taxRegularCents,
    required this.taxFifthRuleCents,
    required this.fifthRuleApplicable,
  });

  /// Remaining taxable income without the severance (input).
  final int taxableIncomeWithoutSeveranceCents;

  /// Severance pay (input).
  final int severanceCents;

  /// Income tax on the taxable income without severance (baseline).
  final int taxWithoutSeveranceCents;

  /// Total income tax under regular taxation: tax(zvE + severance).
  final int taxRegularCents;

  /// Total income tax under the Fünftelregelung (§ 34 Abs. 1 EStG).
  final int taxFifthRuleCents;

  /// Rough income bunching check (spec §5, M3): `true`/`false` when the
  /// inputs for the check were provided, `null` when not checked.
  /// When `false`, the Fünftelregelung is most likely not available and
  /// [savingsCents] should not be presented as achievable.
  final bool? fifthRuleApplicable;

  /// Savings from the Fünftelregelung (>= 0; the assessment only applies
  /// § 34 when it is beneficial).
  int get savingsCents => max(0, taxRegularCents - taxFifthRuleCents);

  /// Tax attributable to the severance (regular taxation).
  int get taxOnSeveranceRegularCents => taxRegularCents - taxWithoutSeveranceCents;

  /// Tax attributable to the severance (Fünftelregelung).
  int get taxOnSeveranceFifthRuleCents => taxFifthRuleCents - taxWithoutSeveranceCents;

  /// Since 2025 the Fünftelregelung is no longer applied in wage tax
  /// withholding: the employer withholds tax under regular taxation and
  /// the savings are refunded only with the income tax assessment.
  bool get refundOnlyViaTaxReturn => savingsCents > 0;
}

/// Rough income bunching check ("Zusammenballung von Einkünften",
/// spec §5, M3).
///
/// [severanceCents]: severance paid in the year.
/// [otherIncomeYearCents]: income actually earned in the payout year
/// besides the severance (wage until exit, wage from a new job, ALG is
/// ignored here).
/// [foregoneIncomeCents]: income the employee would have earned until
/// the end of the year had the employment continued.
///
/// This is a heuristic, not a legal assessment — borderline cases must
/// be checked by a tax adviser.
bool incomeBunchingGiven({
  required int severanceCents,
  required int otherIncomeYearCents,
  required int foregoneIncomeCents,
}) =>
    severanceCents + otherIncomeYearCents > foregoneIncomeCents;

/// Compares regular taxation and the Fünftelregelung for a severance.
///
/// [taxableIncomeWithoutSeveranceCents]: taxable income of the payout
/// year **without** the severance (already reduced by deductible
/// expenses etc.). [splitting] for joint assessment.
///
/// Optionally pass [otherIncomeYearCents] and [foregoneIncomeCents] to
/// run the rough income bunching check (see [incomeBunchingGiven]); the
/// result is exposed as [SeveranceTaxResult.fifthRuleApplicable].
SeveranceTaxResult severanceComparison({
  required int taxableIncomeWithoutSeveranceCents,
  required int severanceCents,
  bool splitting = false,
  int progressionIncomeCents = 0,
  int? otherIncomeYearCents,
  int? foregoneIncomeCents,
  ExitParams? params,
}) {
  assert(severanceCents >= 0);
  final p = params ?? ExitParams.year2026();
  final taxableRest = max(0, taxableIncomeWithoutSeveranceCents);

  // § 32b: tax-free wage-replacement benefits in the same year (e.g. ALG 1)
  // raise the average rate applied to the taxable income incl. the severance.
  int tax(int taxableCents) => incomeTaxWithProgression(
        taxableIncomeCents: taxableCents,
        progressionIncomeCents: progressionIncomeCents,
        splitting: splitting,
        params: p,
      );

  final taxBaseline = tax(taxableRest);
  final taxRegular = tax(taxableRest + severanceCents);
  final taxFifthRule =
      taxBaseline + 5 * (tax(taxableRest + severanceCents ~/ 5) - taxBaseline);

  final bool? bunching;
  if (otherIncomeYearCents != null && foregoneIncomeCents != null) {
    bunching = incomeBunchingGiven(
      severanceCents: severanceCents,
      otherIncomeYearCents: otherIncomeYearCents,
      foregoneIncomeCents: foregoneIncomeCents,
    );
  } else {
    bunching = null;
  }

  return SeveranceTaxResult(
    taxableIncomeWithoutSeveranceCents: taxableRest,
    severanceCents: severanceCents,
    taxWithoutSeveranceCents: taxBaseline,
    taxRegularCents: taxRegular,
    taxFifthRuleCents: taxFifthRule,
    fifthRuleApplicable: bunching,
  );
}
