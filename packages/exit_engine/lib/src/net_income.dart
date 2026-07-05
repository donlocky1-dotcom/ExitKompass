/// Net income estimate: combination of M1 (wage tax, solidarity
/// surcharge, church tax) and M2 (social insurance) for an annual gross
/// wage.
library;

import 'm1_income_tax.dart';
import 'm2_social_insurance.dart';
import 'params.dart';

/// Result of the net income estimate (annual amounts in cents).
class NetIncomeResult {
  const NetIncomeResult({required this.taxes, required this.socialInsurance});

  /// Tax deductions (M1).
  final WageTaxResult taxes;

  /// Social insurance deductions (M2).
  final SocialContributions socialInsurance;

  int get grossYearCents => taxes.grossYearCents;

  /// Estimated annual net income.
  int get netYearCents =>
      grossYearCents - taxes.totalTaxCents - socialInsurance.totalCents;

  /// Estimated monthly net income (annual value / 12, rounded half-up).
  int get netMonthCents => (netYearCents / 12).round();
}

/// Estimates the net income for an annual gross wage.
///
/// Simplifications: annual view (no month-by-month payroll), simplified
/// Vorsorgepauschale, statutory health insurance. Details in
/// ASSUMPTIONS.md.
NetIncomeResult annualNetIncome({
  required int grossYearCents,
  required TaxClass taxClass,
  required int age,
  double childAllowanceFactor = 0,
  int totalChildren = 0,
  int childrenUnder25 = 0,
  bool churchMember = false,
  Bundesland state = Bundesland.nordrheinWestfalen,
  double? healthAdditionalRate,
  ExitParams? params,
}) {
  final p = params ?? ExitParams.year2026();
  return NetIncomeResult(
    taxes: annualWageTax(
      grossYearCents: grossYearCents,
      taxClass: taxClass,
      age: age,
      childAllowanceFactor: childAllowanceFactor,
      totalChildren: totalChildren,
      childrenUnder25: childrenUnder25,
      churchMember: churchMember,
      state: state,
      healthAdditionalRate: healthAdditionalRate,
      params: p,
    ),
    socialInsurance: employeeSocialContributions(
      grossYearCents: grossYearCents,
      age: age,
      totalChildren: totalChildren,
      childrenUnder25: childrenUnder25,
      state: state,
      healthAdditionalRate: healthAdditionalRate,
      params: p,
    ),
  );
}
