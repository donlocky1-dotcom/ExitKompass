/// Employee contribution rates of the social insurance system.
///
/// Shared between M2 (contribution calculation) and M1 (the simplified
/// Vorsorgepauschale of § 39b Abs. 2 S. 5 Nr. 3 EStG).
library;

import 'dart:math';

import 'params.dart';

/// Employee share of long-term care insurance (Pflegeversicherung,
/// § 55 SGB XI).
///
/// * Base share 1.8 % (Saxony: 2.3 %, because the Buß- und Bettag public
///   holiday was never abolished there).
/// * Childless surcharge of +0.6 pp from age 23 if the person never had
///   a child ([totalChildren] == 0).
/// * Discount of 0.25 pp per child for the 2nd to 5th child **under 25**
///   ([childrenUnder25]).
double careInsuranceEmployeeRate({
  required SocialInsuranceParams sv,
  required int age,
  required int totalChildren,
  required int childrenUnder25,
  required Bundesland state,
}) {
  assert(childrenUnder25 <= totalChildren,
      'childrenUnder25 cannot exceed totalChildren');
  var rate =
      state == Bundesland.sachsen ? sv.careEmployeeRateSaxony : sv.careEmployeeRate;
  if (totalChildren == 0 && age >= sv.careChildlessFromAge) {
    rate += sv.careChildlessSurchargeEmployee;
  }
  if (childrenUnder25 >= 2) {
    final discounts = min(childrenUnder25 - 1, sv.careDiscountMaxChildren);
    rate -= discounts * sv.careDiscountPerChildFrom2nd;
  }
  return rate;
}

/// Employee share of statutory health insurance: half the general rate
/// plus half the (fund-specific) additional rate (§§ 241, 242 SGB V,
/// parity funding).
double healthInsuranceEmployeeRate({
  required SocialInsuranceParams sv,
  double? additionalRate,
}) =>
    sv.healthGeneralRate / 2 + (additionalRate ?? sv.healthAvgAdditionalRate) / 2;
