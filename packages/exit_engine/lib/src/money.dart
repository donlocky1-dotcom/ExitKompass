/// Helpers for cent-based money arithmetic.
///
/// Engine convention: monetary amounts are `int` values in cents. The
/// income tax formulas of the EStG operate on amounts rounded down to
/// full euros; these helpers encapsulate the conversions.
///
/// Percentage rates are internally scaled to an integer base of 1e6
/// (precondition: at most 6 decimal places, which every rate in the
/// parameter file satisfies). This keeps expressions like
/// `0.6 × amount` exact instead of flipping by one cent due to binary
/// floating-point representation.
library;

/// Scale for integer rate arithmetic (6 decimal places).
const int _scale = 1000000;

int _scaledRate(double rate) {
  final scaled = (rate * _scale).round();
  assert((scaled / _scale - rate).abs() < 1e-9,
      'rate $rate has more than 6 decimal places');
  return scaled;
}

/// Cents → full euros, rounded down (§ 32a Abs. 1 S. 5 EStG: taxable
/// income is rounded down to a full euro amount). Non-negative input only.
int centsToEuroFloor(int cents) {
  assert(cents >= 0, 'non-negative amounts only');
  return cents ~/ 100;
}

/// Full euros → cents.
int euroToCents(int euro) => euro * 100;

/// Share of a cent amount, rounded down to full cents (tax convention:
/// fractions of a cent are disregarded).
int rateFloor(int cents, double rate) => (cents * _scaledRate(rate)) ~/ _scale;

/// Share of a cent amount, rounded half-up to full cents (convention of
/// social insurance contribution accounting).
int rateRound(int cents, double rate) =>
    (cents * _scaledRate(rate) + _scale ~/ 2) ~/ _scale;

/// Share of a cent amount, rounded **up to full euros**, returned in
/// cents (PAP convention for the partial amounts of the
/// Vorsorgepauschale).
int rateCeilToEuro(int cents, double rate) {
  const centsPerEuro = _scale * 100;
  final product = cents * _scaledRate(rate);
  return ((product + centsPerEuro - 1) ~/ centsPerEuro) * 100;
}
