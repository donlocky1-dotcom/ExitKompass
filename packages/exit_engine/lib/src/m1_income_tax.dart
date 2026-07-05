/// M1 – Income tax and wage tax (tax year 2026).
///
/// * Income tax per the tariff formula of § 32a Abs. 1 EStG (basic and
///   splitting tariff), input/output in cents.
/// * Solidarity surcharge (§§ 3, 4 SolzG) and church tax, each computed
///   on an assessment basis that takes child allowances into account
///   (§ 51a EStG).
/// * Annual wage tax for tax classes I–VI per § 39b Abs. 2 EStG with a
///   **simplified** Vorsorgepauschale – intended as a net-income
///   estimate, not a certified PAP implementation (see ASSUMPTIONS.md).
library;

import 'dart:math';

import 'money.dart';
import 'params.dart';
import 'sv_rates.dart';

/// German wage tax classes I–VI (Steuerklassen, § 38b EStG).
enum TaxClass { i, ii, iii, iv, v, vi }

/// Income tax per the tariff of § 32a Abs. 1 EStG.
///
/// [taxableIncomeCents]: taxable income (zvE) in cents (negative values
/// are treated as 0). With [splitting], the splitting procedure of
/// § 32a Abs. 5 EStG is applied (double the tax on half the income).
/// Returns the annual tax in cents (rounded down to full euros,
/// § 32a Abs. 1 S. 6 EStG).
int incomeTax({
  required int taxableIncomeCents,
  bool splitting = false,
  ExitParams? params,
}) {
  final p = params ?? ExitParams.year2026();
  if (taxableIncomeCents <= 0) return 0;
  if (splitting) {
    return euroToCents(2 * _tariffEuro(centsToEuroFloor(taxableIncomeCents ~/ 2), p.tariff));
  }
  return euroToCents(_tariffEuro(centsToEuroFloor(taxableIncomeCents), p.tariff));
}

/// Basic tariff on a taxable income in full euros; result in full euros
/// (rounded down).
int _tariffEuro(int x, TaxTariffParams t) {
  if (x <= t.basicAllowanceEuro) return 0;
  final double tax;
  if (x <= t.zone2EndEuro) {
    final y = (x - t.basicAllowanceEuro) / 10000.0;
    tax = (t.zone2QuadraticCoeff * y + t.zone2LinearCoeff) * y;
  } else if (x <= t.zone3EndEuro) {
    final z = (x - t.zone2EndEuro) / 10000.0;
    tax = (t.zone3QuadraticCoeff * z + t.zone3LinearCoeff) * z + t.zone3Constant;
  } else if (x <= t.zone4EndEuro) {
    tax = t.zone4Rate * x - t.zone4DeductionEuro;
  } else {
    tax = t.zone5Rate * x - t.zone5DeductionEuro;
  }
  return tax.floor();
}

/// Assessment basis for the solidarity surcharge and church tax
/// (§ 51a Abs. 2 EStG): the notional income tax on the taxable income
/// reduced by child allowances.
///
/// [childAllowanceFactor] corresponds to the Kinderfreibetrag counter on
/// the wage tax card: 1.0 per child with both allowance halves
/// (e.g. tax class III/IV), 0.5 per child with one half.
int surchargeTaxBase({
  required int taxableIncomeCents,
  double childAllowanceFactor = 0,
  bool splitting = false,
  ExitParams? params,
}) {
  final p = params ?? ExitParams.year2026();
  final allowance =
      (childAllowanceFactor * p.children.allowancePerChildBothParentsCents).round();
  return incomeTax(
    taxableIncomeCents: max(0, taxableIncomeCents - allowance),
    splitting: splitting,
    params: p,
  );
}

/// Solidarity surcharge on an income tax amount (already reduced by
/// child allowances where applicable; §§ 3, 4 SolzG 1995): 5.5 %, but 0
/// up to the exemption limit and capped at 11.9 % of the amount above
/// the limit within the taper zone.
///
/// [splitting] selects the doubled exemption limit (joint assessment or
/// tax class III in wage tax withholding).
int solidaritySurcharge({
  required int assessmentBasisCents,
  bool splitting = false,
  ExitParams? params,
}) {
  final p = params ?? ExitParams.year2026();
  final exemption =
      splitting ? p.soli.exemptionSplittingCents : p.soli.exemptionSingleCents;
  if (assessmentBasisCents <= exemption) return 0;
  final regular = rateFloor(assessmentBasisCents, p.soli.rate);
  final tapered = rateFloor(assessmentBasisCents - exemption, p.soli.taperRate);
  return min(regular, tapered);
}

/// Church tax on an income tax amount (already reduced by child
/// allowances where applicable): 8 % in Bavaria/Baden-Württemberg,
/// 9 % elsewhere.
int churchTax({
  required int assessmentBasisCents,
  required Bundesland state,
  ExitParams? params,
}) {
  final p = params ?? ExitParams.year2026();
  if (assessmentBasisCents <= 0) return 0;
  return rateFloor(assessmentBasisCents, p.churchTax.rateFor(state));
}

/// Simplified Vorsorgepauschale per § 39b Abs. 2 S. 5 Nr. 3 EStG, based
/// on the annual gross wage.
///
/// Partial amounts (each rounded up to full euros, as in the PAP):
/// * pension insurance: employee share of the gross wage up to the
///   pension/unemployment ceiling,
/// * health/care insurance: employee shares up to the health/care
///   ceiling, but at least the minimum allowance (12 % of the wage,
///   capped at 1,900 € / 3,000 € in tax class III).
int vorsorgepauschale({
  required int grossYearCents,
  required TaxClass taxClass,
  required int age,
  int totalChildren = 0,
  int childrenUnder25 = 0,
  Bundesland state = Bundesland.nordrheinWestfalen,
  double? healthAdditionalRate,
  ExitParams? params,
}) {
  final p = params ?? ExitParams.year2026();
  final sv = p.socialInsurance;
  final pensionBase = min(grossYearCents, sv.ceilingPensionUnempYearCents);
  final healthBase = min(grossYearCents, sv.ceilingHealthCareYearCents);

  final pensionPart = rateCeilToEuro(pensionBase, sv.pensionEmployeeRate);
  final healthPart = rateCeilToEuro(healthBase,
      healthInsuranceEmployeeRate(sv: sv, additionalRate: healthAdditionalRate));
  final carePart = rateCeilToEuro(
      healthBase,
      careInsuranceEmployeeRate(
        sv: sv,
        age: age,
        totalChildren: totalChildren,
        childrenUnder25: childrenUnder25,
        state: state,
      ));

  final minCap = taxClass == TaxClass.iii
      ? p.payroll.minHealthCareAllowanceCapClass3Cents
      : p.payroll.minHealthCareAllowanceCapCents;
  final minHealthCare =
      min(rateCeilToEuro(grossYearCents, p.payroll.minHealthCareAllowanceRate), minCap);

  return pensionPart + max(healthPart + carePart, minHealthCare);
}

/// Result of the annual wage tax calculation (all amounts in cents).
class WageTaxResult {
  const WageTaxResult({
    required this.grossYearCents,
    required this.taxableCents,
    required this.vorsorgepauschaleCents,
    required this.wageTaxCents,
    required this.soliCents,
    required this.churchTaxCents,
  });

  /// Annual gross wage (input).
  final int grossYearCents;

  /// Taxable annual amount of the wage tax calculation (gross minus lump
  /// sums and Vorsorgepauschale).
  final int taxableCents;

  /// Applied (simplified) Vorsorgepauschale.
  final int vorsorgepauschaleCents;

  /// Annual wage tax.
  final int wageTaxCents;

  /// Solidarity surcharge on the wage tax (§ 51a: with child allowances).
  final int soliCents;

  /// Church tax on the wage tax (§ 51a: with child allowances);
  /// 0 without church membership.
  final int churchTaxCents;

  /// Sum of all tax deductions.
  int get totalTaxCents => wageTaxCents + soliCents + churchTaxCents;
}

/// Annual wage tax per § 39b Abs. 2 EStG (simplified) as a net-income
/// estimate.
///
/// Deduction order: Arbeitnehmer-Pauschbetrag (classes I–V),
/// Sonderausgaben-Pauschbetrag (classes I–V), single-parent relief
/// (class II), Vorsorgepauschale. The taxable annual amount is then
/// taxed with: the basic tariff (I, II, IV), the splitting tariff (III),
/// or the formula of § 39b Abs. 2 S. 7 EStG (V, VI).
///
/// [childAllowanceFactor] only affects the solidarity surcharge and
/// church tax (§ 51a Abs. 2a EStG), not the wage tax itself.
WageTaxResult annualWageTax({
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
  final payroll = p.payroll;

  final vp = vorsorgepauschale(
    grossYearCents: grossYearCents,
    taxClass: taxClass,
    age: age,
    totalChildren: totalChildren,
    childrenUnder25: childrenUnder25,
    state: state,
    healthAdditionalRate: healthAdditionalRate,
    params: p,
  );

  var deductions = vp;
  if (taxClass != TaxClass.vi) {
    deductions += payroll.employeeLumpSumCents + payroll.specialExpensesLumpSumCents;
  }
  if (taxClass == TaxClass.ii) {
    deductions += payroll.singleParentReliefCents;
  }
  final taxable = max(0, grossYearCents - deductions);

  final wageTax = _wageTaxOnTaxable(taxable, taxClass, p);

  // Surcharge taxes are based on the notional wage tax with child
  // allowances deducted (§ 51a Abs. 2a EStG).
  final allowance =
      (childAllowanceFactor * p.children.allowancePerChildBothParentsCents).round();
  final surchargeBase = allowance == 0
      ? wageTax
      : _wageTaxOnTaxable(max(0, taxable - allowance), taxClass, p);

  final soli = solidaritySurcharge(
    assessmentBasisCents: surchargeBase,
    splitting: taxClass == TaxClass.iii,
    params: p,
  );
  final church = churchMember
      ? churchTax(
          assessmentBasisCents: surchargeBase,
          state: state,
          params: p,
        )
      : 0;

  return WageTaxResult(
    grossYearCents: grossYearCents,
    taxableCents: taxable,
    vorsorgepauschaleCents: vp,
    wageTaxCents: wageTax,
    soliCents: soli,
    churchTaxCents: church,
  );
}

int _wageTaxOnTaxable(int taxableCents, TaxClass taxClass, ExitParams p) {
  switch (taxClass) {
    case TaxClass.i:
    case TaxClass.ii:
    case TaxClass.iv:
      return incomeTax(taxableIncomeCents: taxableCents, params: p);
    case TaxClass.iii:
      return incomeTax(taxableIncomeCents: taxableCents, splitting: true, params: p);
    case TaxClass.v:
    case TaxClass.vi:
      return euroToCents(_wageTaxClass56Euro(centsToEuroFloor(taxableCents), p));
  }
}

/// Wage tax for classes V/VI per § 39b Abs. 2 S. 7 EStG (input and
/// output in full euros).
///
/// Base formula: twice the difference between the tariff tax on 1.25
/// times and on 0.75 times the taxable annual amount; at least 14 %.
/// The marginal burden is capped at 42 % for the part above
/// `threshold1`, fixed at 42 % above `threshold2` and at 45 % above
/// `threshold3` (implemented like the PAP block MLST5/6).
int _wageTaxClass56Euro(int x, ExitParams p) {
  final payroll = p.payroll;
  if (x <= 0) return 0;

  if (x > payroll.class56Threshold2Euro) {
    var tax = _class56Base(payroll.class56Threshold2Euro, p) +
        (x - payroll.class56Threshold2Euro) * p.tariff.zone4Rate;
    if (x > payroll.class56Threshold3Euro) {
      tax += (x - payroll.class56Threshold3Euro) * (p.tariff.zone5Rate - p.tariff.zone4Rate);
    }
    return tax.floor();
  }
  final base = _class56Base(x, p);
  if (x > payroll.class56Threshold1Euro) {
    final cap = _class56Base(payroll.class56Threshold1Euro, p) +
        (x - payroll.class56Threshold1Euro) * p.tariff.zone4Rate;
    return min(base, cap).floor();
  }
  return base.floor();
}

/// Base formula of § 39b Abs. 2 S. 7 EStG including the 14 % minimum.
double _class56Base(int x, ExitParams p) {
  final doubled =
      2.0 * (_tariffEuro((1.25 * x).floor(), p.tariff) - _tariffEuro((0.75 * x).floor(), p.tariff));
  final minimum = x * p.payroll.class56MinRate;
  return max(doubled, minimum);
}
