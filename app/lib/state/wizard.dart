import 'package:exit_engine/exit_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which situation the user is in (spec step 1). Only biases which
/// scenario is emphasised; the engine always computes all four.
enum Situation { kuendigungErhalten, aufhebungAngeboten, ueberlegeZuKuendigen, nurInfo }

/// All wizard inputs. Euro fields are whole euros (converted to cents when
/// the engine is called); defaults make the result screen computable
/// immediately.
class WizardData {
  WizardData({
    this.situation = Situation.kuendigungErhalten,
    this.birthYear = 1985,
    this.taxClass = TaxClass.i,
    this.childAllowanceFactor = 0,
    this.childrenUnder25 = 0,
    this.hasChildForAlg = false,
    this.churchMember = false,
    this.state = Bundesland.nordrheinWestfalen,
    this.healthAdditionalRatePercent = 2.9,
    this.grossMonthEuro = 5000,
    this.annualExtrasEuro = 0,
    DateTime? entryDate,
    DateTime? regularEndDate,
    this.severanceGrossEuro = 50000,
    DateTime? exitDate,
    this.paidRelease = false,
    this.settlementsEuro = 0,
    this.horizonMonths = 24,
  })  : entryDate = entryDate ?? _defaultEntry,
        regularEndDate = regularEndDate ?? _defaultExit,
        exitDate = exitDate ?? _defaultExit;

  static final DateTime _defaultEntry = DateTime(2015, 1, 1);
  static final DateTime _defaultExit = DateTime(DateTime.now().year, DateTime.now().month + 3, 1);

  final Situation situation;
  final int birthYear;
  final TaxClass taxClass;
  final double childAllowanceFactor;
  final int childrenUnder25;
  final bool hasChildForAlg;
  final bool churchMember;
  final Bundesland state;
  final double healthAdditionalRatePercent;
  final int grossMonthEuro;
  final int annualExtrasEuro;
  final DateTime entryDate;
  final DateTime regularEndDate;
  final int severanceGrossEuro;
  final DateTime exitDate;
  final bool paidRelease;
  final int settlementsEuro;
  final int horizonMonths;

  WizardData copyWith({
    Situation? situation,
    int? birthYear,
    TaxClass? taxClass,
    double? childAllowanceFactor,
    int? childrenUnder25,
    bool? hasChildForAlg,
    bool? churchMember,
    Bundesland? state,
    double? healthAdditionalRatePercent,
    int? grossMonthEuro,
    int? annualExtrasEuro,
    DateTime? entryDate,
    DateTime? regularEndDate,
    int? severanceGrossEuro,
    DateTime? exitDate,
    bool? paidRelease,
    int? settlementsEuro,
    int? horizonMonths,
  }) {
    return WizardData(
      situation: situation ?? this.situation,
      birthYear: birthYear ?? this.birthYear,
      taxClass: taxClass ?? this.taxClass,
      childAllowanceFactor: childAllowanceFactor ?? this.childAllowanceFactor,
      childrenUnder25: childrenUnder25 ?? this.childrenUnder25,
      hasChildForAlg: hasChildForAlg ?? this.hasChildForAlg,
      churchMember: churchMember ?? this.churchMember,
      state: state ?? this.state,
      healthAdditionalRatePercent:
          healthAdditionalRatePercent ?? this.healthAdditionalRatePercent,
      grossMonthEuro: grossMonthEuro ?? this.grossMonthEuro,
      annualExtrasEuro: annualExtrasEuro ?? this.annualExtrasEuro,
      entryDate: entryDate ?? this.entryDate,
      regularEndDate: regularEndDate ?? this.regularEndDate,
      severanceGrossEuro: severanceGrossEuro ?? this.severanceGrossEuro,
      exitDate: exitDate ?? this.exitDate,
      paidRelease: paidRelease ?? this.paidRelease,
      settlementsEuro: settlementsEuro ?? this.settlementsEuro,
      horizonMonths: horizonMonths ?? this.horizonMonths,
    );
  }

  /// Runs the M5 aggregator on the current inputs.
  AggregateResult compute() {
    final now = DateTime.now();
    return aggregateScenarios(
      profile: UserProfile(
        birthYear: birthYear,
        taxClass: taxClass,
        state: state,
        childAllowanceFactor: childAllowanceFactor,
        churchMember: churchMember,
        healthAdditionalRate: healthAdditionalRatePercent / 100,
        hasChildForAlg: hasChildForAlg,
        totalChildren: childrenUnder25,
        childrenUnder25: childrenUnder25,
      ),
      employment: EmploymentData(
        grossMonthCents: grossMonthEuro * 100,
        annualExtrasCents: annualExtrasEuro * 100,
        entryDate: entryDate,
        regularEndDate: regularEndDate,
      ),
      offer: OfferData(
        severanceGrossCents: severanceGrossEuro * 100,
        exitDate: exitDate,
        paidRelease: paidRelease,
        settlementsCents: settlementsEuro * 100,
      ),
      referenceDate: DateTime(now.year, now.month, 1),
      horizonMonths: horizonMonths,
    );
  }
}

/// Holds the wizard inputs; screens read and mutate via this controller.
class WizardController extends StateNotifier<WizardData> {
  WizardController() : super(WizardData());

  void update(WizardData Function(WizardData) mutate) => state = mutate(state);
}

final wizardProvider =
    StateNotifierProvider<WizardController, WizardData>((ref) => WizardController());
