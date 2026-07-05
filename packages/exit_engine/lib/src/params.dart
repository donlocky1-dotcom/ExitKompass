import 'dart:convert';

import 'params_2026_data.dart';

/// German federal states (Bundesländer).
///
/// Relevant to the engine for the church tax rate (8 % in BW/BY, 9 %
/// elsewhere) and the higher employee share of long-term care insurance
/// in Saxony.
enum Bundesland {
  badenWuerttemberg('BW'),
  bayern('BY'),
  berlin('BE'),
  brandenburg('BB'),
  bremen('HB'),
  hamburg('HH'),
  hessen('HE'),
  mecklenburgVorpommern('MV'),
  niedersachsen('NI'),
  nordrheinWestfalen('NW'),
  rheinlandPfalz('RP'),
  saarland('SL'),
  sachsen('SN'),
  sachsenAnhalt('ST'),
  schleswigHolstein('SH'),
  thueringen('TH');

  const Bundesland(this.code);

  /// Two-letter state code as used in `params_2026.json`.
  final String code;

  static Bundesland fromCode(String code) => values.firstWhere(
        (b) => b.code == code.toUpperCase(),
        orElse: () => throw ArgumentError.value(code, 'code', 'unknown state code'),
      );
}

Map<String, dynamic> _map(Object? v) => (v as Map).cast<String, dynamic>();

double _rate(Object? v) => (v as num).toDouble();

int _int(Object? v) => (v as num).toInt();

/// Converts a euro value from the JSON file to cents.
int _euroToCents(Object? v) => ((v as num) * 100).round();

/// Tariff parameters of § 32a Abs. 1 EStG (zone bounds in euros as in the
/// statute, because the tariff formula operates on taxable income rounded
/// down to full euros).
class TaxTariffParams {
  const TaxTariffParams({
    required this.basicAllowanceEuro,
    required this.zone2EndEuro,
    required this.zone3EndEuro,
    required this.zone4EndEuro,
    required this.zone2QuadraticCoeff,
    required this.zone2LinearCoeff,
    required this.zone3QuadraticCoeff,
    required this.zone3LinearCoeff,
    required this.zone3Constant,
    required this.zone4Rate,
    required this.zone4DeductionEuro,
    required this.zone5Rate,
    required this.zone5DeductionEuro,
  });

  factory TaxTariffParams.fromJson(Map<String, dynamic> json) => TaxTariffParams(
        basicAllowanceEuro: _int(json['grundfreibetrag_euro']),
        zone2EndEuro: _int(json['zone2_ende_euro']),
        zone3EndEuro: _int(json['zone3_ende_euro']),
        zone4EndEuro: _int(json['zone4_ende_euro']),
        zone2QuadraticCoeff: _rate(json['zone2_koeff_quadratisch']),
        zone2LinearCoeff: _rate(json['zone2_koeff_linear']),
        zone3QuadraticCoeff: _rate(json['zone3_koeff_quadratisch']),
        zone3LinearCoeff: _rate(json['zone3_koeff_linear']),
        zone3Constant: _rate(json['zone3_konstante']),
        zone4Rate: _rate(json['zone4_satz']),
        zone4DeductionEuro: _rate(json['zone4_abzug_euro']),
        zone5Rate: _rate(json['zone5_satz']),
        zone5DeductionEuro: _rate(json['zone5_abzug_euro']),
      );

  /// Grundfreibetrag (basic tax-free allowance).
  final int basicAllowanceEuro;
  final int zone2EndEuro;
  final int zone3EndEuro;
  final int zone4EndEuro;
  final double zone2QuadraticCoeff;
  final double zone2LinearCoeff;
  final double zone3QuadraticCoeff;
  final double zone3LinearCoeff;
  final double zone3Constant;
  final double zone4Rate;
  final double zone4DeductionEuro;
  final double zone5Rate;
  final double zone5DeductionEuro;
}

/// Wage tax withholding parameters (§ 39b EStG, PAP 2026).
class PayrollTaxParams {
  const PayrollTaxParams({
    required this.employeeLumpSumCents,
    required this.specialExpensesLumpSumCents,
    required this.singleParentReliefCents,
    required this.class56MinRate,
    required this.class56Threshold1Euro,
    required this.class56Threshold2Euro,
    required this.class56Threshold3Euro,
    required this.minHealthCareAllowanceRate,
    required this.minHealthCareAllowanceCapCents,
    required this.minHealthCareAllowanceCapClass3Cents,
  });

  factory PayrollTaxParams.fromJson(Map<String, dynamic> json) {
    final vp = _map(json['vorsorgepauschale']);
    return PayrollTaxParams(
      employeeLumpSumCents: _euroToCents(json['arbeitnehmer_pauschbetrag_euro']),
      specialExpensesLumpSumCents: _euroToCents(json['sonderausgaben_pauschbetrag_euro']),
      singleParentReliefCents:
          _euroToCents(json['entlastungsbetrag_alleinerziehende_euro']),
      class56MinRate: _rate(json['stkl5_6_mindestsatz']),
      class56Threshold1Euro: _int(json['stkl5_6_grenze1_euro']),
      class56Threshold2Euro: _int(json['stkl5_6_grenze2_euro']),
      class56Threshold3Euro: _int(json['stkl5_6_grenze3_euro']),
      minHealthCareAllowanceRate: _rate(vp['mindest_kvpv_satz']),
      minHealthCareAllowanceCapCents: _euroToCents(vp['mindest_kvpv_max_euro']),
      minHealthCareAllowanceCapClass3Cents:
          _euroToCents(vp['mindest_kvpv_max_stkl3_euro']),
    );
  }

  /// Arbeitnehmer-Pauschbetrag (§ 9a EStG).
  final int employeeLumpSumCents;

  /// Sonderausgaben-Pauschbetrag (§ 10c EStG).
  final int specialExpensesLumpSumCents;

  /// Entlastungsbetrag für Alleinerziehende (§ 24b EStG, tax class II).
  final int singleParentReliefCents;

  /// Minimum rate for tax classes V/VI (§ 39b Abs. 2 S. 7 EStG).
  final double class56MinRate;
  final int class56Threshold1Euro;
  final int class56Threshold2Euro;
  final int class56Threshold3Euro;

  /// Minimum Vorsorgepauschale for health/care insurance: rate and caps.
  final double minHealthCareAllowanceRate;
  final int minHealthCareAllowanceCapCents;
  final int minHealthCareAllowanceCapClass3Cents;
}

/// Child allowances and child benefit (§ 32 Abs. 6, § 66 EStG).
class ChildParams {
  const ChildParams({
    required this.childAllowancePerParentCents,
    required this.beaAllowancePerParentCents,
    required this.allowancePerChildBothParentsCents,
    required this.childBenefitMonthCents,
  });

  factory ChildParams.fromJson(Map<String, dynamic> json) => ChildParams(
        childAllowancePerParentCents:
            _euroToCents(json['kinderfreibetrag_je_elternteil_euro']),
        beaAllowancePerParentCents:
            _euroToCents(json['bea_freibetrag_je_elternteil_euro']),
        allowancePerChildBothParentsCents:
            _euroToCents(json['freibetrag_je_kind_beide_elternteile_euro']),
        childBenefitMonthCents: _euroToCents(json['kindergeld_monat_euro']),
      );

  /// Kinderfreibetrag per parent.
  final int childAllowancePerParentCents;

  /// BEA allowance (Betreuung/Erziehung/Ausbildung) per parent.
  final int beaAllowancePerParentCents;

  /// Full allowance per child (both halves, Kinderfreibetrag + BEA).
  final int allowancePerChildBothParentsCents;

  /// Kindergeld per month (informational; not used by M1–M4).
  final int childBenefitMonthCents;
}

/// Solidarity surcharge (§§ 3, 4 SolzG 1995).
class SolidaritySurchargeParams {
  const SolidaritySurchargeParams({
    required this.rate,
    required this.exemptionSingleCents,
    required this.exemptionSplittingCents,
    required this.taperRate,
  });

  factory SolidaritySurchargeParams.fromJson(Map<String, dynamic> json) =>
      SolidaritySurchargeParams(
        rate: _rate(json['satz']),
        exemptionSingleCents: _euroToCents(json['freigrenze_grundtarif_euro']),
        exemptionSplittingCents: _euroToCents(json['freigrenze_splitting_euro']),
        taperRate: _rate(json['milderungszone_satz']),
      );

  final double rate;

  /// Freigrenze for the basic tariff.
  final int exemptionSingleCents;

  /// Freigrenze for splitting (joint assessment / tax class III).
  final int exemptionSplittingCents;

  /// Taper zone rate (Milderungszone, 11.9 %).
  final double taperRate;
}

/// Church tax rates per federal state.
class ChurchTaxParams {
  const ChurchTaxParams({required this.ratesByState});

  factory ChurchTaxParams.fromJson(Map<String, dynamic> json) {
    final raw = _map(json['saetze_je_bundesland']);
    return ChurchTaxParams(
      ratesByState: {
        for (final entry in raw.entries) Bundesland.fromCode(entry.key): _rate(entry.value),
      },
    );
  }

  final Map<Bundesland, double> ratesByState;

  double rateFor(Bundesland state) => ratesByState[state]!;
}

/// Contribution rates and assessment ceilings of the social insurance
/// system, 2026.
class SocialInsuranceParams {
  const SocialInsuranceParams({
    required this.ceilingHealthCareYearCents,
    required this.ceilingPensionUnempYearCents,
    required this.mandatoryInsuranceThresholdYearCents,
    required this.healthGeneralRate,
    required this.healthReducedRate,
    required this.healthAvgAdditionalRate,
    required this.careRateTotal,
    required this.careEmployeeRate,
    required this.careEmployeeRateSaxony,
    required this.careChildlessSurchargeEmployee,
    required this.careChildlessFromAge,
    required this.careDiscountPerChildFrom2nd,
    required this.careDiscountMaxChildren,
    required this.pensionRate,
    required this.pensionEmployeeRate,
    required this.unempRate,
    required this.unempEmployeeRate,
  });

  factory SocialInsuranceParams.fromJson(Map<String, dynamic> json) =>
      SocialInsuranceParams(
        ceilingHealthCareYearCents: _euroToCents(json['bbg_kv_pv_jahr_euro']),
        ceilingPensionUnempYearCents: _euroToCents(json['bbg_rv_av_jahr_euro']),
        mandatoryInsuranceThresholdYearCents:
            _euroToCents(json['versicherungspflichtgrenze_jahr_euro']),
        healthGeneralRate: _rate(json['kv_allgemeiner_satz']),
        healthReducedRate: _rate(json['kv_ermaessigter_satz']),
        healthAvgAdditionalRate: _rate(json['kv_zusatzbeitrag_durchschnitt']),
        careRateTotal: _rate(json['pv_satz_gesamt']),
        careEmployeeRate: _rate(json['pv_an_anteil_normal']),
        careEmployeeRateSaxony: _rate(json['pv_an_anteil_sachsen']),
        careChildlessSurchargeEmployee: _rate(json['pv_kinderlosenzuschlag_an']),
        careChildlessFromAge: _int(json['pv_kinderlos_ab_alter']),
        careDiscountPerChildFrom2nd: _rate(json['pv_abschlag_je_kind_ab_zweitem']),
        careDiscountMaxChildren: _int(json['pv_abschlag_max_anzahl_kinder']),
        pensionRate: _rate(json['rv_satz']),
        pensionEmployeeRate: _rate(json['rv_an_anteil']),
        unempRate: _rate(json['av_satz']),
        unempEmployeeRate: _rate(json['av_an_anteil']),
      );

  /// Beitragsbemessungsgrenze KV/PV (health/care), per year.
  final int ceilingHealthCareYearCents;

  /// Beitragsbemessungsgrenze RV/AV (pension/unemployment), per year.
  final int ceilingPensionUnempYearCents;

  /// Versicherungspflichtgrenze (JAEG), per year.
  final int mandatoryInsuranceThresholdYearCents;

  final double healthGeneralRate;
  final double healthReducedRate;
  final double healthAvgAdditionalRate;
  final double careRateTotal;
  final double careEmployeeRate;
  final double careEmployeeRateSaxony;
  final double careChildlessSurchargeEmployee;
  final int careChildlessFromAge;
  final double careDiscountPerChildFrom2nd;
  final int careDiscountMaxChildren;
  final double pensionRate;
  final double pensionEmployeeRate;
  final double unempRate;
  final double unempEmployeeRate;
}

/// One row of the benefit duration table of § 147 Abs. 2 SGB III.
class AlgDurationRow {
  const AlgDurationRow({
    required this.minInsuredMonths,
    required this.minAge,
    required this.entitlementDays,
  });

  factory AlgDurationRow.fromJson(Map<String, dynamic> json) => AlgDurationRow(
        minInsuredMonths: _int(json['versicherungsmonate_min']),
        minAge: _int(json['mindestalter']),
        entitlementDays: _int(json['anspruch_tage']),
      );

  final int minInsuredMonths;
  final int minAge;
  final int entitlementDays;
}

/// Parameters for the benefit suspension on severance pay
/// (Ruhen bei Entlassungsentschädigung, § 158 SGB III).
class Suspension158Params {
  const Suspension158Params({
    required this.baseShare,
    required this.reductionPer5YearsTenure,
    required this.ageThreshold,
    required this.reductionPer5YearsAge,
    required this.minShare,
    required this.maxSuspensionDays,
  });

  factory Suspension158Params.fromJson(Map<String, dynamic> json) => Suspension158Params(
        baseShare: _rate(json['anteil_basis']),
        reductionPer5YearsTenure:
            _rate(json['minderung_je_5_jahre_betriebszugehoerigkeit']),
        ageThreshold: _int(json['minderung_je_5_lebensjahre_ueber']),
        reductionPer5YearsAge: _rate(json['minderung_je_5_lebensjahre_satz']),
        minShare: _rate(json['anteil_minimum']),
        maxSuspensionDays: _int(json['max_ruhen_tage']),
      );

  final double baseShare;
  final double reductionPer5YearsTenure;
  final int ageThreshold;
  final double reductionPer5YearsAge;
  final double minShare;
  final int maxSuspensionDays;
}

/// Parameters of unemployment benefit (ALG 1, SGB III).
class Alg1Params {
  const Alg1Params({
    required this.benefitRateGeneral,
    required this.benefitRateWithChild,
    required this.socialSecurityLumpRate,
    required this.daysPerMonth,
    required this.daysPerYear,
    required this.durationTable,
    required this.blockingPeriodWeeks,
    required this.blockingPeriodMinReductionShare,
    required this.suspension158,
  });

  factory Alg1Params.fromJson(Map<String, dynamic> json) => Alg1Params(
        benefitRateGeneral: _rate(json['leistungssatz_allgemein']),
        benefitRateWithChild: _rate(json['leistungssatz_erhoeht']),
        socialSecurityLumpRate: _rate(json['sv_pauschale']),
        daysPerMonth: _int(json['tage_je_monat']),
        daysPerYear: _int(json['tage_je_jahr']),
        durationTable: [
          for (final row in json['anspruchsdauer_tabelle'] as List)
            AlgDurationRow.fromJson(_map(row)),
        ],
        blockingPeriodWeeks: _int(json['sperrzeit_arbeitsaufgabe_wochen']),
        blockingPeriodMinReductionShare:
            _rate(json['sperrzeit_minderung_anteil_mindestens']),
        suspension158: Suspension158Params.fromJson(_map(json['ruhen_158'])),
      );

  final double benefitRateGeneral;
  final double benefitRateWithChild;

  /// Flat social insurance deduction of § 153 SGB III (20 %).
  final double socialSecurityLumpRate;
  final int daysPerMonth;
  final int daysPerYear;
  final List<AlgDurationRow> durationTable;

  /// Sperrzeit (blocking period) for giving up a job, in weeks (§ 159).
  final int blockingPeriodWeeks;

  /// Minimum reduction of the entitlement duration (§ 148 Abs. 1 Nr. 4).
  final double blockingPeriodMinReductionShare;

  final Suspension158Params suspension158;
}

/// Complete engine parameter set for one tax/contribution year.
class ExitParams {
  const ExitParams({
    required this.year,
    required this.tariff,
    required this.payroll,
    required this.children,
    required this.soli,
    required this.churchTax,
    required this.socialInsurance,
    required this.alg1,
  });

  factory ExitParams.fromJson(Map<String, dynamic> json) => ExitParams(
        year: _int(_map(json['_meta'])['jahr']),
        tariff: TaxTariffParams.fromJson(_map(json['einkommensteuer_32a'])),
        payroll: PayrollTaxParams.fromJson(_map(json['lohnsteuer_39b'])),
        children: ChildParams.fromJson(_map(json['kinder'])),
        soli: SolidaritySurchargeParams.fromJson(_map(json['solidaritaetszuschlag'])),
        churchTax: ChurchTaxParams.fromJson(_map(json['kirchensteuer'])),
        socialInsurance: SocialInsuranceParams.fromJson(_map(json['sozialversicherung'])),
        alg1: Alg1Params.fromJson(_map(json['alg1'])),
      );

  factory ExitParams.fromJsonString(String jsonString) =>
      ExitParams.fromJson((jsonDecode(jsonString) as Map).cast<String, dynamic>());

  /// The 2026 parameter set, loaded from the embedded copy of
  /// `lib/params/params_2026.json`.
  factory ExitParams.year2026() => _params2026 ??= ExitParams.fromJsonString(params2026Json);

  static ExitParams? _params2026;

  final int year;
  final TaxTariffParams tariff;
  final PayrollTaxParams payroll;
  final ChildParams children;
  final SolidaritySurchargeParams soli;
  final ChurchTaxParams churchTax;
  final SocialInsuranceParams socialInsurance;
  final Alg1Params alg1;
}
