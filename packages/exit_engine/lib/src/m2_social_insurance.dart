/// M2 – Social insurance: employee contributions 2026.
///
/// Computes the employee shares of health, long-term care, pension and
/// unemployment insurance on an annual basis, correctly capped at both
/// contribution assessment ceilings (KV/PV: 69,750 €, RV/AV: 101,400 €).
/// Assumption: employee with statutory insurance (no private health
/// insurance, no midijob transition zone).
library;

import 'dart:math';

import 'money.dart';
import 'params.dart';
import 'sv_rates.dart';

/// Employee social insurance contributions (annual amounts in cents).
class SocialContributions {
  const SocialContributions({
    required this.grossYearCents,
    required this.healthCents,
    required this.careCents,
    required this.pensionCents,
    required this.unempCents,
    required this.healthRateEmployee,
    required this.careRateEmployee,
  });

  /// Annual gross wage (input).
  final int grossYearCents;

  /// Health insurance (incl. half the additional rate).
  final int healthCents;

  /// Long-term care insurance (incl. childless surcharge or child
  /// discounts).
  final int careCents;

  /// Pension insurance.
  final int pensionCents;

  /// Unemployment insurance.
  final int unempCents;

  /// Applied employee health insurance rate (informational).
  final double healthRateEmployee;

  /// Applied employee care insurance rate (informational).
  final double careRateEmployee;

  /// Sum of all employee contributions.
  int get totalCents => healthCents + careCents + pensionCents + unempCents;
}

/// Employee social insurance contributions on an annual gross wage.
///
/// * [age], [totalChildren], [childrenUnder25]: control the care
///   insurance childless surcharge (+0.6 pp from age 23 without
///   children) and the child discounts (−0.25 pp per child for children
///   2–5 under 25).
/// * [state]: Saxony has an employee care insurance share 0.5 pp higher.
/// * [healthAdditionalRate]: fund-specific additional rate (default:
///   2.9 % average for 2026).
///
/// Contributions are rounded half-up to full cents.
SocialContributions employeeSocialContributions({
  required int grossYearCents,
  required int age,
  int totalChildren = 0,
  int childrenUnder25 = 0,
  Bundesland state = Bundesland.nordrheinWestfalen,
  double? healthAdditionalRate,
  ExitParams? params,
}) {
  assert(grossYearCents >= 0);
  final p = params ?? ExitParams.year2026();
  final sv = p.socialInsurance;

  final healthCareBase = min(grossYearCents, sv.ceilingHealthCareYearCents);
  final pensionUnempBase = min(grossYearCents, sv.ceilingPensionUnempYearCents);

  final healthRate =
      healthInsuranceEmployeeRate(sv: sv, additionalRate: healthAdditionalRate);
  final careRate = careInsuranceEmployeeRate(
    sv: sv,
    age: age,
    totalChildren: totalChildren,
    childrenUnder25: childrenUnder25,
    state: state,
  );

  return SocialContributions(
    grossYearCents: grossYearCents,
    healthCents: rateRound(healthCareBase, healthRate),
    careCents: rateRound(healthCareBase, careRate),
    pensionCents: rateRound(pensionUnempBase, sv.pensionEmployeeRate),
    unempCents: rateRound(pensionUnempBase, sv.unempEmployeeRate),
    healthRateEmployee: healthRate,
    careRateEmployee: careRate,
  );
}
