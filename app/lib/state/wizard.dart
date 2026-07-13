import 'package:exit_engine/exit_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which situation the user is in (spec step 1). Only biases which
/// scenario is emphasised; the engine always computes all four.
enum Situation { kuendigungErhalten, aufhebungAngeboten, ueberlegeZuKuendigen, nurInfo }

extension SituationLabel on Situation {
  String get label => switch (this) {
        Situation.kuendigungErhalten => 'Kündigung erhalten',
        Situation.aufhebungAngeboten => 'Aufhebungsvertrag angeboten',
        Situation.ueberlegeZuKuendigen => 'Überlege selbst zu kündigen',
        Situation.nurInfo => 'Nur informieren',
      };
}

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
    this.anticipatesOperationalDismissal = false,
    this.horizonMonths = 12,
    this.kuendigungsArt = KuendigungsArt.unbekannt,
    this.monthlyExpensesEuro = 2500,
    this.savingsEuro = 10000,
    DateTime? noticeDate,
  })  : entryDate = entryDate ?? _defaultEntry,
        regularEndDate = regularEndDate ?? _defaultExit,
        exitDate = exitDate ?? _defaultExit,
        noticeDate = noticeDate ?? _today;

  /// A blank starting point: the core figures (salary, birth year, entry/exit
  /// dates, severance) are left unset so the input form starts empty and the
  /// analysis asks for them before showing any numbers. Non-core details keep
  /// quiet, sensible defaults. The plain [WizardData] constructor still carries
  /// example defaults (used for tests, the PDF dossier and previews).
  factory WizardData.empty() => WizardData(
        birthYear: 0,
        grossMonthEuro: 0,
        severanceGrossEuro: 0,
        annualExtrasEuro: 0,
        settlementsEuro: 0,
        entryDate: unsetDate,
        regularEndDate: unsetDate,
        exitDate: unsetDate,
      );

  static final DateTime _defaultEntry = DateTime(2015, 1, 1);
  static final DateTime _today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  static final DateTime _defaultExit = DateTime(DateTime.now().year, DateTime.now().month + 3, 1);

  /// Sentinel for "no date chosen yet" (the input form shows it as blank and
  /// requires a real pick). Kept before the date picker's firstDate.
  static final DateTime unsetDate = DateTime(1900);

  static bool _dateIsSet(DateTime d) => d.year > 1900;

  /// Whether the essential figures for a meaningful net/tax analysis are
  /// present: salary, birth year and the employment start / notice-period end.
  /// The severance offer and detail fields (church tax, health add-on,
  /// savings…) stay optional.
  bool get hasCoreData =>
      grossMonthEuro > 0 &&
      birthYear > 1900 &&
      _dateIsSet(entryDate) &&
      _dateIsSet(regularEndDate);

  /// The exit date to reckon tenure and age from: the explicit offer exit date
  /// when set, otherwise the end of the notice period.
  DateTime get _exitOrEnd => _dateIsSet(exitDate) ? exitDate : regularEndDate;

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

  /// Whether a termination agreement documents that it anticipates a lawful
  /// operational (betriebsbedingt) employer dismissal. Drives whether the
  /// ALG blocking period (Sperrzeit) is expected for the S2 scenario.
  final bool anticipatesOperationalDismissal;

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
    bool? anticipatesOperationalDismissal,
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
      anticipatesOperationalDismissal:
          anticipatesOperationalDismissal ?? this.anticipatesOperationalDismissal,
      horizonMonths: horizonMonths ?? this.horizonMonths,
      kuendigungsArt: kuendigungsArt ?? this.kuendigungsArt,
      monthlyExpensesEuro: monthlyExpensesEuro ?? this.monthlyExpensesEuro,
      savingsEuro: savingsEuro ?? this.savingsEuro,
      noticeDate: noticeDate ?? this.noticeDate,
    );
  }

  /// Serialises all inputs (for local persistence via shared_preferences).
  Map<String, dynamic> toJson() => {
        'situation': situation.index,
        'birthYear': birthYear,
        'taxClass': taxClass.index,
        'childAllowanceFactor': childAllowanceFactor,
        'childrenUnder25': childrenUnder25,
        'hasChildForAlg': hasChildForAlg,
        'churchMember': churchMember,
        'state': state.code,
        'healthAdditionalRatePercent': healthAdditionalRatePercent,
        'grossMonthEuro': grossMonthEuro,
        'annualExtrasEuro': annualExtrasEuro,
        'entryDate': entryDate.millisecondsSinceEpoch,
        'regularEndDate': regularEndDate.millisecondsSinceEpoch,
        'severanceGrossEuro': severanceGrossEuro,
        'exitDate': exitDate.millisecondsSinceEpoch,
        'paidRelease': paidRelease,
        'settlementsEuro': settlementsEuro,
        'anticipatesOperationalDismissal': anticipatesOperationalDismissal,
        'horizonMonths': horizonMonths,
        'kuendigungsArt': kuendigungsArt.index,
        'monthlyExpensesEuro': monthlyExpensesEuro,
        'savingsEuro': savingsEuro,
        'noticeDate': noticeDate.millisecondsSinceEpoch,
      };

  static WizardData fromJson(Map<String, dynamic> j) {
    DateTime at(String k) => DateTime.fromMillisecondsSinceEpoch(j[k] as int);
    T atEnum<T>(List<T> values, Object? idx, T fallback) =>
        (idx is int && idx >= 0 && idx < values.length) ? values[idx] : fallback;
    return WizardData(
      situation: atEnum(Situation.values, j['situation'], Situation.kuendigungErhalten),
      birthYear: j['birthYear'] as int,
      taxClass: atEnum(TaxClass.values, j['taxClass'], TaxClass.i),
      childAllowanceFactor: (j['childAllowanceFactor'] as num).toDouble(),
      childrenUnder25: j['childrenUnder25'] as int,
      hasChildForAlg: j['hasChildForAlg'] as bool,
      churchMember: j['churchMember'] as bool,
      state: Bundesland.fromCode(j['state'] as String),
      healthAdditionalRatePercent:
          (j['healthAdditionalRatePercent'] as num).toDouble(),
      grossMonthEuro: j['grossMonthEuro'] as int,
      annualExtrasEuro: j['annualExtrasEuro'] as int,
      entryDate: at('entryDate'),
      regularEndDate: at('regularEndDate'),
      severanceGrossEuro: j['severanceGrossEuro'] as int,
      exitDate: at('exitDate'),
      paidRelease: j['paidRelease'] as bool,
      settlementsEuro: j['settlementsEuro'] as int,
      anticipatesOperationalDismissal:
          j['anticipatesOperationalDismissal'] as bool,
      horizonMonths: j['horizonMonths'] as int,
      kuendigungsArt:
          atEnum(KuendigungsArt.values, j['kuendigungsArt'], KuendigungsArt.unbekannt),
      monthlyExpensesEuro: j['monthlyExpensesEuro'] as int,
      savingsEuro: j['savingsEuro'] as int,
      noticeDate: at('noticeDate'),
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
        exitDate: _exitOrEnd,
        paidRelease: paidRelease,
        settlementsCents: settlementsEuro * 100,
        // A betriebsbedingte Kündigung is itself the anticipated operational
        // dismissal, so choosing that ground already lifts the S2 Sperrzeit
        // (subject to notice period and a moderate severance, checked in M5).
        anticipatesOperationalDismissal: anticipatesOperationalDismissal ||
            kuendigungsArt == KuendigungsArt.betriebsbedingt,
      ),
      referenceDate: DateTime(now.year, now.month, 1),
      horizonMonths: horizonMonths,
      // After ALG 1, model the means-tested Bürgergeld floor from the
      // household finances (savings spent down to the SGB II allowance).
      includeBuergergeld: true,
      startingAssetsCents: savingsEuro * 100,
      monthlyExpensesCents: monthlyExpensesEuro * 100,
    );
  }

  /// Full years of tenure (entry → exit), clamped like the estimator.
  int get tenureYears =>
      (_exitOrEnd.difference(entryDate).inDays / 365).floor().clamp(0, 60);

  /// Age at the exit date.
  int get ageAtExit => _exitOrEnd.year - birthYear;

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

/// Persists the wizard inputs. Implemented by the Drift repository (native)
/// and a shared_preferences store (used on the web preview).
abstract class WizardStore {
  Future<void> save(WizardData data);
  Future<void> clear();
}

/// Holds the wizard inputs; screens read and mutate via this controller.
/// When a [WizardStore] is provided, every change is persisted.
class WizardController extends StateNotifier<WizardData> {
  // Named parameters cannot bind a private field directly, so the
  // initializing-formal lint does not apply here.
  WizardController({WizardStore? repository, WizardData? initial})
      // ignore: prefer_initializing_formals
      : _repository = repository,
        super(initial ?? WizardData.empty());

  final WizardStore? _repository;

  void update(WizardData Function(WizardData) mutate) {
    state = mutate(state);
    _repository?.save(state);
  }

  /// Resets the inputs to a blank form and deletes the saved state
  /// (spec §13: "Daten vollständig löschen").
  Future<void> clearSaved() async {
    state = WizardData.empty();
    await _repository?.clear();
  }
}

final wizardProvider =
    StateNotifierProvider<WizardController, WizardData>((ref) => WizardController());
