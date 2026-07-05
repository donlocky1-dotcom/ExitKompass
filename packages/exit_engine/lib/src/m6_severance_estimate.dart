/// M6 – Severance amount estimate ("Wie viel Abfindung ist realistisch?").
///
/// Estimates a **negotiable range** for a severance from the rule-of-thumb
/// used before German labour courts (0.5 gross monthly salaries per year
/// of tenure) scaled by a negotiation-strength factor band, capped by the
/// upper limits of § 10 KSchG.
///
/// This is negotiation orientation, **not** a legal entitlement: a general
/// statutory claim to a severance does not exist (see the Ratgeber). All
/// amounts are `int` cents.
library;

import 'dart:math';

/// How strong the employee's negotiating position is. The description of
/// each level mirrors what typically drives it (dismissal grounds,
/// company size, tenure/age, procedural errors).
enum NegotiationStrength {
  /// e.g. small business, clear grounds for dismissal.
  schwach,

  /// the usual Regelabfindung situation.
  standard,

  /// e.g. doubtful grounds, procedural errors, strong dismissal protection.
  stark,
}

extension NegotiationStrengthBand on NegotiationStrength {
  /// Lower / upper factor of the band (multiples of a monthly salary per
  /// year of tenure).
  (double, double) get factorBand => switch (this) {
        NegotiationStrength.schwach => (0.25, 0.5),
        NegotiationStrength.standard => (0.5, 1.0),
        NegotiationStrength.stark => (1.0, 1.5),
      };
}

/// Result of the severance estimate (all amounts in cents).
class SeveranceEstimate {
  const SeveranceEstimate({
    required this.lowCents,
    required this.pointCents,
    required this.highCents,
    required this.factorLow,
    required this.factorHigh,
    required this.regelabfindungCents,
    required this.cappedByKschG10,
    required this.kschG10CapMonths,
    required this.smallBusiness,
  });

  /// Lower end of the negotiable range.
  final int lowCents;

  /// Orientation point value: the midpoint of the negotiable range.
  final int pointCents;

  /// Upper end of the negotiable range.
  final int highCents;

  final double factorLow;
  final double factorHigh;

  /// The Regelabfindung after § 1a KSchG (factor 0.5), for reference.
  final int regelabfindungCents;

  /// Whether the upper end was capped by the § 10 KSchG limit.
  final bool cappedByKschG10;

  /// The applicable § 10 KSchG cap in monthly salaries (0 if none).
  final int kschG10CapMonths;

  /// Whether this looks like a small business (< 10 employees) where the
  /// KSchG generally does not apply – weakening the position.
  final bool smallBusiness;
}

/// Estimates a negotiable severance range.
///
/// [grossMonthCents]: gross monthly salary (incl. pro-rata bonuses).
/// [tenureYears]: full years of tenure. [age]: age in years.
/// [strength]: chosen negotiating position. [smallBusiness]: fewer than
/// 10 employees (KSchG usually does not apply).
SeveranceEstimate estimateSeverance({
  required int grossMonthCents,
  required int tenureYears,
  required int age,
  required NegotiationStrength strength,
  bool smallBusiness = false,
}) {
  assert(grossMonthCents >= 0);
  final years = max(0, tenureYears);
  final perYear = grossMonthCents; // one monthly salary per year, ×factor below
  final base = perYear * years; // = grossMonth × years (factor 1.0)

  var (factorLow, factorHigh) = strength.factorBand;
  // A small business weakens the position: shade the band down a notch.
  if (smallBusiness) {
    factorLow = max(0.0, factorLow - 0.25);
    factorHigh = max(factorLow, factorHigh - 0.25);
  }

  final regelabfindung = (base * 0.5).round();
  var low = (base * factorLow).round();
  var high = (base * factorHigh).round();

  // § 10 KSchG upper limits (only for a court-ordered dissolution, but a
  // useful ceiling for orientation): 15 monthly salaries from age 50 with
  // 15+ years, 18 from age 55 with 20+ years.
  var capMonths = 0;
  if (age >= 55 && years >= 20) {
    capMonths = 18;
  } else if (age >= 50 && years >= 15) {
    capMonths = 15;
  }
  var capped = false;
  if (capMonths > 0) {
    final capCents = grossMonthCents * capMonths;
    if (high > capCents) {
      high = capCents;
      capped = true;
    }
    low = min(low, high);
  }

  return SeveranceEstimate(
    lowCents: low,
    pointCents: ((low + high) / 2).round(),
    highCents: high,
    factorLow: factorLow,
    factorHigh: factorHigh,
    regelabfindungCents: regelabfindung,
    cappedByKschG10: capped,
    kschG10CapMonths: capMonths,
    smallBusiness: smallBusiness,
  );
}
