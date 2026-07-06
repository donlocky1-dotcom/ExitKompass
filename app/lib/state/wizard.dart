import 'package:exit_engine/exit_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wizard_repository.dart';

/// Which situation the user is in (spec step 1). Only biases which
/// scenario is emphasised; the engine always computes all four.
enum Situation { kuendigungErhalten, aufhebungAngeboten, ueberlegeZuKuendigen, nurInfo }

/// Grounds for the dismissal. Informs the suggested negotiation strength
/// of the severance estimate (M6).
enum KuendigungsArt { unbekannt, betriebsbedingt, verhaltensbedingt, personenbedingt }

extension KuendigungsArtSuggestion on KuendigungsArt {
  /// A sensible default negotiation strength for this ground.
  NegotiationStrength get suggestedStrength => switch (this) {
        // Operational dismissals are the classic § 1a / severance case.
        KuendigungsArt.betriebsbedingt => NegotiationStrength.standard,
        // Behaviour-based dismissals: if the grounds hold, the position is weaker.
        KuendigungsArt.verhaltensbedingt => NegotiationStrength.schwach,
        KuendigungsArt.personenbedingt => NegotiationStrength.standard,
        KuendigungsArt.unbekannt => NegotiationStrength.standard,
      };

  String get label => switch (this) {
        KuendigungsArt.unbekannt => 'Unklar / sonstige',
        KuendigungsArt.betriebsbedingt => 'Betriebsbedingt',
        KuendigungsArt.verhaltensbedingt => 'Verhaltensbedingt',
        KuendigungsArt.personenbedingt => 'Personenbedingt',
      };
}

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
    this.kuendigungsArt = KuendigungsArt.unbekannt,
    this.monthlyExpensesEuro = 2500,
    this.savingsEuro = 10000,
    DateTime? noticeDate,
  })  : entryDate = entryDate ?? _defaultEntry,
        regularEndDate = regularEndDate ?? _defaultExit,
        exitDate = exitDate ?? _defaultExit,
        noticeDate = noticeDate ?? _today;

  static final DateTime _defaultEntry = DateTime(2015, 1, 1);
  static final DateTime _today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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

  /// Grounds for the dismissal (persisted; suggests the estimate strength).
  final KuendigungsArt kuendigungsArt;

  /// Household living expenses per month, in whole euros (bridge planner).
  final int monthlyExpensesEuro;

  /// Savings available today, in whole euros (bridge planner starting point).
  final int savingsEuro;

  /// Date the written termination / offer was received (drives the
  /// § 4 KSchG deadline in the timeline; not used by the engine).
  final DateTime noticeDate;

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
    KuendigungsArt? kuendigungsArt,
    int? monthlyExpensesEuro,
    int? savingsEuro,
    DateTime? noticeDate,
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
      kuendigungsArt: kuendigungsArt ?? this.kuendigungsArt,
      monthlyExpensesEuro: monthlyExpensesEuro ?? this.monthlyExpensesEuro,
      savingsEuro: savingsEuro ?? this.savingsEuro,
      noticeDate: noticeDate ?? this.noticeDate,
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

  /// Full years of tenure (entry → exit), clamped like the estimator.
  int get tenureYears =>
      (exitDate.difference(entryDate).inDays / 365).floor().clamp(0, 60);

  /// Age at the exit date.
  int get ageAtExit => exitDate.year - birthYear;

  /// A negotiable severance range from the persisted inputs (M6). The
  /// negotiation [strength] defaults to the one suggested by the persisted
  /// Kündigungsgrund; [smallBusiness] is transient UI state and defaults to
  /// false. Shared by the on-screen estimator and the PDF dossier so both
  /// stay in sync.
  SeveranceEstimate estimateSeveranceRange({
    NegotiationStrength? strength,
    bool smallBusiness = false,
  }) =>
      estimateSeverance(
        grossMonthCents: grossMonthEuro * 100,
        tenureYears: tenureYears,
        age: ageAtExit,
        strength: strength ?? kuendigungsArt.suggestedStrength,
        smallBusiness: smallBusiness,
      );

  /// Projects the household's cash runway for the given [scenario] using the
  /// persisted monthly expenses and savings (M7). Reuses an existing
  /// [aggregate] result if provided (else computes one).
  RunwayPlan runwayFor(ScenarioType scenario, {AggregateResult? aggregate}) {
    final result = aggregate ?? compute();
    return computeRunway(
      monthlyNetCents: result.scenarios[scenario]!.monthlyNetCents,
      startingSavingsCents: savingsEuro * 100,
      monthlyExpensesCents: monthlyExpensesEuro * 100,
    );
  }
}

/// Holds the wizard inputs; screens read and mutate via this controller.
/// When a [WizardRepository] is provided, every change is persisted.
class WizardController extends StateNotifier<WizardData> {
  // Named parameters cannot bind a private field directly, so the
  // initializing-formal lint does not apply here.
  WizardController({WizardRepository? repository, WizardData? initial})
      // ignore: prefer_initializing_formals
      : _repository = repository,
        super(initial ?? WizardData());

  final WizardRepository? _repository;

  void update(WizardData Function(WizardData) mutate) {
    state = mutate(state);
    _repository?.save(state);
  }

  /// Resets the inputs to their defaults and deletes the saved state
  /// (spec §13: "Daten vollständig löschen").
  Future<void> clearSaved() async {
    state = WizardData();
    await _repository?.clear();
  }
}

final wizardProvider =
    StateNotifierProvider<WizardController, WizardData>((ref) => WizardController());
