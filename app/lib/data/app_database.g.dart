// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WizardStatesTable extends WizardStates
    with TableInfo<$WizardStatesTable, WizardState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WizardStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _situationMeta = const VerificationMeta(
    'situation',
  );
  @override
  late final GeneratedColumn<int> situation = GeneratedColumn<int>(
    'situation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthYearMeta = const VerificationMeta(
    'birthYear',
  );
  @override
  late final GeneratedColumn<int> birthYear = GeneratedColumn<int>(
    'birth_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxClassMeta = const VerificationMeta(
    'taxClass',
  );
  @override
  late final GeneratedColumn<int> taxClass = GeneratedColumn<int>(
    'tax_class',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _childAllowanceFactorMeta =
      const VerificationMeta('childAllowanceFactor');
  @override
  late final GeneratedColumn<double> childAllowanceFactor =
      GeneratedColumn<double>(
        'child_allowance_factor',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _childrenUnder25Meta = const VerificationMeta(
    'childrenUnder25',
  );
  @override
  late final GeneratedColumn<int> childrenUnder25 = GeneratedColumn<int>(
    'children_under25',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasChildForAlgMeta = const VerificationMeta(
    'hasChildForAlg',
  );
  @override
  late final GeneratedColumn<bool> hasChildForAlg = GeneratedColumn<bool>(
    'has_child_for_alg',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_child_for_alg" IN (0, 1))',
    ),
  );
  static const VerificationMeta _churchMemberMeta = const VerificationMeta(
    'churchMember',
  );
  @override
  late final GeneratedColumn<bool> churchMember = GeneratedColumn<bool>(
    'church_member',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("church_member" IN (0, 1))',
    ),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthAdditionalRatePercentMeta =
      const VerificationMeta('healthAdditionalRatePercent');
  @override
  late final GeneratedColumn<double> healthAdditionalRatePercent =
      GeneratedColumn<double>(
        'health_additional_rate_percent',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _grossMonthEuroMeta = const VerificationMeta(
    'grossMonthEuro',
  );
  @override
  late final GeneratedColumn<int> grossMonthEuro = GeneratedColumn<int>(
    'gross_month_euro',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annualExtrasEuroMeta = const VerificationMeta(
    'annualExtrasEuro',
  );
  @override
  late final GeneratedColumn<int> annualExtrasEuro = GeneratedColumn<int>(
    'annual_extras_euro',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryDateMeta = const VerificationMeta(
    'entryDate',
  );
  @override
  late final GeneratedColumn<DateTime> entryDate = GeneratedColumn<DateTime>(
    'entry_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regularEndDateMeta = const VerificationMeta(
    'regularEndDate',
  );
  @override
  late final GeneratedColumn<DateTime> regularEndDate =
      GeneratedColumn<DateTime>(
        'regular_end_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _severanceGrossEuroMeta =
      const VerificationMeta('severanceGrossEuro');
  @override
  late final GeneratedColumn<int> severanceGrossEuro = GeneratedColumn<int>(
    'severance_gross_euro',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exitDateMeta = const VerificationMeta(
    'exitDate',
  );
  @override
  late final GeneratedColumn<DateTime> exitDate = GeneratedColumn<DateTime>(
    'exit_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidReleaseMeta = const VerificationMeta(
    'paidRelease',
  );
  @override
  late final GeneratedColumn<bool> paidRelease = GeneratedColumn<bool>(
    'paid_release',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paid_release" IN (0, 1))',
    ),
  );
  static const VerificationMeta _settlementsEuroMeta = const VerificationMeta(
    'settlementsEuro',
  );
  @override
  late final GeneratedColumn<int> settlementsEuro = GeneratedColumn<int>(
    'settlements_euro',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _horizonMonthsMeta = const VerificationMeta(
    'horizonMonths',
  );
  @override
  late final GeneratedColumn<int> horizonMonths = GeneratedColumn<int>(
    'horizon_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noticeDateMeta = const VerificationMeta(
    'noticeDate',
  );
  @override
  late final GeneratedColumn<DateTime> noticeDate = GeneratedColumn<DateTime>(
    'notice_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kuendigungsArtMeta = const VerificationMeta(
    'kuendigungsArt',
  );
  @override
  late final GeneratedColumn<int> kuendigungsArt = GeneratedColumn<int>(
    'kuendigungs_art',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    situation,
    birthYear,
    taxClass,
    childAllowanceFactor,
    childrenUnder25,
    hasChildForAlg,
    churchMember,
    state,
    healthAdditionalRatePercent,
    grossMonthEuro,
    annualExtrasEuro,
    entryDate,
    regularEndDate,
    severanceGrossEuro,
    exitDate,
    paidRelease,
    settlementsEuro,
    horizonMonths,
    noticeDate,
    kuendigungsArt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wizard_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<WizardState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('situation')) {
      context.handle(
        _situationMeta,
        situation.isAcceptableOrUnknown(data['situation']!, _situationMeta),
      );
    } else if (isInserting) {
      context.missing(_situationMeta);
    }
    if (data.containsKey('birth_year')) {
      context.handle(
        _birthYearMeta,
        birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta),
      );
    } else if (isInserting) {
      context.missing(_birthYearMeta);
    }
    if (data.containsKey('tax_class')) {
      context.handle(
        _taxClassMeta,
        taxClass.isAcceptableOrUnknown(data['tax_class']!, _taxClassMeta),
      );
    } else if (isInserting) {
      context.missing(_taxClassMeta);
    }
    if (data.containsKey('child_allowance_factor')) {
      context.handle(
        _childAllowanceFactorMeta,
        childAllowanceFactor.isAcceptableOrUnknown(
          data['child_allowance_factor']!,
          _childAllowanceFactorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_childAllowanceFactorMeta);
    }
    if (data.containsKey('children_under25')) {
      context.handle(
        _childrenUnder25Meta,
        childrenUnder25.isAcceptableOrUnknown(
          data['children_under25']!,
          _childrenUnder25Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_childrenUnder25Meta);
    }
    if (data.containsKey('has_child_for_alg')) {
      context.handle(
        _hasChildForAlgMeta,
        hasChildForAlg.isAcceptableOrUnknown(
          data['has_child_for_alg']!,
          _hasChildForAlgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hasChildForAlgMeta);
    }
    if (data.containsKey('church_member')) {
      context.handle(
        _churchMemberMeta,
        churchMember.isAcceptableOrUnknown(
          data['church_member']!,
          _churchMemberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_churchMemberMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('health_additional_rate_percent')) {
      context.handle(
        _healthAdditionalRatePercentMeta,
        healthAdditionalRatePercent.isAcceptableOrUnknown(
          data['health_additional_rate_percent']!,
          _healthAdditionalRatePercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_healthAdditionalRatePercentMeta);
    }
    if (data.containsKey('gross_month_euro')) {
      context.handle(
        _grossMonthEuroMeta,
        grossMonthEuro.isAcceptableOrUnknown(
          data['gross_month_euro']!,
          _grossMonthEuroMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grossMonthEuroMeta);
    }
    if (data.containsKey('annual_extras_euro')) {
      context.handle(
        _annualExtrasEuroMeta,
        annualExtrasEuro.isAcceptableOrUnknown(
          data['annual_extras_euro']!,
          _annualExtrasEuroMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annualExtrasEuroMeta);
    }
    if (data.containsKey('entry_date')) {
      context.handle(
        _entryDateMeta,
        entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta),
      );
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('regular_end_date')) {
      context.handle(
        _regularEndDateMeta,
        regularEndDate.isAcceptableOrUnknown(
          data['regular_end_date']!,
          _regularEndDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_regularEndDateMeta);
    }
    if (data.containsKey('severance_gross_euro')) {
      context.handle(
        _severanceGrossEuroMeta,
        severanceGrossEuro.isAcceptableOrUnknown(
          data['severance_gross_euro']!,
          _severanceGrossEuroMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_severanceGrossEuroMeta);
    }
    if (data.containsKey('exit_date')) {
      context.handle(
        _exitDateMeta,
        exitDate.isAcceptableOrUnknown(data['exit_date']!, _exitDateMeta),
      );
    } else if (isInserting) {
      context.missing(_exitDateMeta);
    }
    if (data.containsKey('paid_release')) {
      context.handle(
        _paidReleaseMeta,
        paidRelease.isAcceptableOrUnknown(
          data['paid_release']!,
          _paidReleaseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paidReleaseMeta);
    }
    if (data.containsKey('settlements_euro')) {
      context.handle(
        _settlementsEuroMeta,
        settlementsEuro.isAcceptableOrUnknown(
          data['settlements_euro']!,
          _settlementsEuroMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settlementsEuroMeta);
    }
    if (data.containsKey('horizon_months')) {
      context.handle(
        _horizonMonthsMeta,
        horizonMonths.isAcceptableOrUnknown(
          data['horizon_months']!,
          _horizonMonthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_horizonMonthsMeta);
    }
    if (data.containsKey('notice_date')) {
      context.handle(
        _noticeDateMeta,
        noticeDate.isAcceptableOrUnknown(data['notice_date']!, _noticeDateMeta),
      );
    } else if (isInserting) {
      context.missing(_noticeDateMeta);
    }
    if (data.containsKey('kuendigungs_art')) {
      context.handle(
        _kuendigungsArtMeta,
        kuendigungsArt.isAcceptableOrUnknown(
          data['kuendigungs_art']!,
          _kuendigungsArtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WizardState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WizardState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      situation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}situation'],
      )!,
      birthYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_year'],
      )!,
      taxClass: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_class'],
      )!,
      childAllowanceFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}child_allowance_factor'],
      )!,
      childrenUnder25: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}children_under25'],
      )!,
      hasChildForAlg: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_child_for_alg'],
      )!,
      churchMember: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}church_member'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      healthAdditionalRatePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}health_additional_rate_percent'],
      )!,
      grossMonthEuro: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gross_month_euro'],
      )!,
      annualExtrasEuro: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}annual_extras_euro'],
      )!,
      entryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}entry_date'],
      )!,
      regularEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}regular_end_date'],
      )!,
      severanceGrossEuro: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}severance_gross_euro'],
      )!,
      exitDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}exit_date'],
      )!,
      paidRelease: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paid_release'],
      )!,
      settlementsEuro: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}settlements_euro'],
      )!,
      horizonMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}horizon_months'],
      )!,
      noticeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}notice_date'],
      )!,
      kuendigungsArt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kuendigungs_art'],
      )!,
    );
  }

  @override
  $WizardStatesTable createAlias(String alias) {
    return $WizardStatesTable(attachedDatabase, alias);
  }
}

class WizardState extends DataClass implements Insertable<WizardState> {
  /// Always 0 – there is exactly one saved state.
  final int id;
  final int situation;
  final int birthYear;
  final int taxClass;
  final double childAllowanceFactor;
  final int childrenUnder25;
  final bool hasChildForAlg;
  final bool churchMember;
  final String state;
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
  final DateTime noticeDate;

  /// Added in schema v2. Default 0 = KuendigungsArt.unbekannt so existing
  /// rows upgrade cleanly.
  final int kuendigungsArt;
  const WizardState({
    required this.id,
    required this.situation,
    required this.birthYear,
    required this.taxClass,
    required this.childAllowanceFactor,
    required this.childrenUnder25,
    required this.hasChildForAlg,
    required this.churchMember,
    required this.state,
    required this.healthAdditionalRatePercent,
    required this.grossMonthEuro,
    required this.annualExtrasEuro,
    required this.entryDate,
    required this.regularEndDate,
    required this.severanceGrossEuro,
    required this.exitDate,
    required this.paidRelease,
    required this.settlementsEuro,
    required this.horizonMonths,
    required this.noticeDate,
    required this.kuendigungsArt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['situation'] = Variable<int>(situation);
    map['birth_year'] = Variable<int>(birthYear);
    map['tax_class'] = Variable<int>(taxClass);
    map['child_allowance_factor'] = Variable<double>(childAllowanceFactor);
    map['children_under25'] = Variable<int>(childrenUnder25);
    map['has_child_for_alg'] = Variable<bool>(hasChildForAlg);
    map['church_member'] = Variable<bool>(churchMember);
    map['state'] = Variable<String>(state);
    map['health_additional_rate_percent'] = Variable<double>(
      healthAdditionalRatePercent,
    );
    map['gross_month_euro'] = Variable<int>(grossMonthEuro);
    map['annual_extras_euro'] = Variable<int>(annualExtrasEuro);
    map['entry_date'] = Variable<DateTime>(entryDate);
    map['regular_end_date'] = Variable<DateTime>(regularEndDate);
    map['severance_gross_euro'] = Variable<int>(severanceGrossEuro);
    map['exit_date'] = Variable<DateTime>(exitDate);
    map['paid_release'] = Variable<bool>(paidRelease);
    map['settlements_euro'] = Variable<int>(settlementsEuro);
    map['horizon_months'] = Variable<int>(horizonMonths);
    map['notice_date'] = Variable<DateTime>(noticeDate);
    map['kuendigungs_art'] = Variable<int>(kuendigungsArt);
    return map;
  }

  WizardStatesCompanion toCompanion(bool nullToAbsent) {
    return WizardStatesCompanion(
      id: Value(id),
      situation: Value(situation),
      birthYear: Value(birthYear),
      taxClass: Value(taxClass),
      childAllowanceFactor: Value(childAllowanceFactor),
      childrenUnder25: Value(childrenUnder25),
      hasChildForAlg: Value(hasChildForAlg),
      churchMember: Value(churchMember),
      state: Value(state),
      healthAdditionalRatePercent: Value(healthAdditionalRatePercent),
      grossMonthEuro: Value(grossMonthEuro),
      annualExtrasEuro: Value(annualExtrasEuro),
      entryDate: Value(entryDate),
      regularEndDate: Value(regularEndDate),
      severanceGrossEuro: Value(severanceGrossEuro),
      exitDate: Value(exitDate),
      paidRelease: Value(paidRelease),
      settlementsEuro: Value(settlementsEuro),
      horizonMonths: Value(horizonMonths),
      noticeDate: Value(noticeDate),
      kuendigungsArt: Value(kuendigungsArt),
    );
  }

  factory WizardState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WizardState(
      id: serializer.fromJson<int>(json['id']),
      situation: serializer.fromJson<int>(json['situation']),
      birthYear: serializer.fromJson<int>(json['birthYear']),
      taxClass: serializer.fromJson<int>(json['taxClass']),
      childAllowanceFactor: serializer.fromJson<double>(
        json['childAllowanceFactor'],
      ),
      childrenUnder25: serializer.fromJson<int>(json['childrenUnder25']),
      hasChildForAlg: serializer.fromJson<bool>(json['hasChildForAlg']),
      churchMember: serializer.fromJson<bool>(json['churchMember']),
      state: serializer.fromJson<String>(json['state']),
      healthAdditionalRatePercent: serializer.fromJson<double>(
        json['healthAdditionalRatePercent'],
      ),
      grossMonthEuro: serializer.fromJson<int>(json['grossMonthEuro']),
      annualExtrasEuro: serializer.fromJson<int>(json['annualExtrasEuro']),
      entryDate: serializer.fromJson<DateTime>(json['entryDate']),
      regularEndDate: serializer.fromJson<DateTime>(json['regularEndDate']),
      severanceGrossEuro: serializer.fromJson<int>(json['severanceGrossEuro']),
      exitDate: serializer.fromJson<DateTime>(json['exitDate']),
      paidRelease: serializer.fromJson<bool>(json['paidRelease']),
      settlementsEuro: serializer.fromJson<int>(json['settlementsEuro']),
      horizonMonths: serializer.fromJson<int>(json['horizonMonths']),
      noticeDate: serializer.fromJson<DateTime>(json['noticeDate']),
      kuendigungsArt: serializer.fromJson<int>(json['kuendigungsArt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'situation': serializer.toJson<int>(situation),
      'birthYear': serializer.toJson<int>(birthYear),
      'taxClass': serializer.toJson<int>(taxClass),
      'childAllowanceFactor': serializer.toJson<double>(childAllowanceFactor),
      'childrenUnder25': serializer.toJson<int>(childrenUnder25),
      'hasChildForAlg': serializer.toJson<bool>(hasChildForAlg),
      'churchMember': serializer.toJson<bool>(churchMember),
      'state': serializer.toJson<String>(state),
      'healthAdditionalRatePercent': serializer.toJson<double>(
        healthAdditionalRatePercent,
      ),
      'grossMonthEuro': serializer.toJson<int>(grossMonthEuro),
      'annualExtrasEuro': serializer.toJson<int>(annualExtrasEuro),
      'entryDate': serializer.toJson<DateTime>(entryDate),
      'regularEndDate': serializer.toJson<DateTime>(regularEndDate),
      'severanceGrossEuro': serializer.toJson<int>(severanceGrossEuro),
      'exitDate': serializer.toJson<DateTime>(exitDate),
      'paidRelease': serializer.toJson<bool>(paidRelease),
      'settlementsEuro': serializer.toJson<int>(settlementsEuro),
      'horizonMonths': serializer.toJson<int>(horizonMonths),
      'noticeDate': serializer.toJson<DateTime>(noticeDate),
      'kuendigungsArt': serializer.toJson<int>(kuendigungsArt),
    };
  }

  WizardState copyWith({
    int? id,
    int? situation,
    int? birthYear,
    int? taxClass,
    double? childAllowanceFactor,
    int? childrenUnder25,
    bool? hasChildForAlg,
    bool? churchMember,
    String? state,
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
    DateTime? noticeDate,
    int? kuendigungsArt,
  }) => WizardState(
    id: id ?? this.id,
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
    noticeDate: noticeDate ?? this.noticeDate,
    kuendigungsArt: kuendigungsArt ?? this.kuendigungsArt,
  );
  WizardState copyWithCompanion(WizardStatesCompanion data) {
    return WizardState(
      id: data.id.present ? data.id.value : this.id,
      situation: data.situation.present ? data.situation.value : this.situation,
      birthYear: data.birthYear.present ? data.birthYear.value : this.birthYear,
      taxClass: data.taxClass.present ? data.taxClass.value : this.taxClass,
      childAllowanceFactor: data.childAllowanceFactor.present
          ? data.childAllowanceFactor.value
          : this.childAllowanceFactor,
      childrenUnder25: data.childrenUnder25.present
          ? data.childrenUnder25.value
          : this.childrenUnder25,
      hasChildForAlg: data.hasChildForAlg.present
          ? data.hasChildForAlg.value
          : this.hasChildForAlg,
      churchMember: data.churchMember.present
          ? data.churchMember.value
          : this.churchMember,
      state: data.state.present ? data.state.value : this.state,
      healthAdditionalRatePercent: data.healthAdditionalRatePercent.present
          ? data.healthAdditionalRatePercent.value
          : this.healthAdditionalRatePercent,
      grossMonthEuro: data.grossMonthEuro.present
          ? data.grossMonthEuro.value
          : this.grossMonthEuro,
      annualExtrasEuro: data.annualExtrasEuro.present
          ? data.annualExtrasEuro.value
          : this.annualExtrasEuro,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      regularEndDate: data.regularEndDate.present
          ? data.regularEndDate.value
          : this.regularEndDate,
      severanceGrossEuro: data.severanceGrossEuro.present
          ? data.severanceGrossEuro.value
          : this.severanceGrossEuro,
      exitDate: data.exitDate.present ? data.exitDate.value : this.exitDate,
      paidRelease: data.paidRelease.present
          ? data.paidRelease.value
          : this.paidRelease,
      settlementsEuro: data.settlementsEuro.present
          ? data.settlementsEuro.value
          : this.settlementsEuro,
      horizonMonths: data.horizonMonths.present
          ? data.horizonMonths.value
          : this.horizonMonths,
      noticeDate: data.noticeDate.present
          ? data.noticeDate.value
          : this.noticeDate,
      kuendigungsArt: data.kuendigungsArt.present
          ? data.kuendigungsArt.value
          : this.kuendigungsArt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WizardState(')
          ..write('id: $id, ')
          ..write('situation: $situation, ')
          ..write('birthYear: $birthYear, ')
          ..write('taxClass: $taxClass, ')
          ..write('childAllowanceFactor: $childAllowanceFactor, ')
          ..write('childrenUnder25: $childrenUnder25, ')
          ..write('hasChildForAlg: $hasChildForAlg, ')
          ..write('churchMember: $churchMember, ')
          ..write('state: $state, ')
          ..write('healthAdditionalRatePercent: $healthAdditionalRatePercent, ')
          ..write('grossMonthEuro: $grossMonthEuro, ')
          ..write('annualExtrasEuro: $annualExtrasEuro, ')
          ..write('entryDate: $entryDate, ')
          ..write('regularEndDate: $regularEndDate, ')
          ..write('severanceGrossEuro: $severanceGrossEuro, ')
          ..write('exitDate: $exitDate, ')
          ..write('paidRelease: $paidRelease, ')
          ..write('settlementsEuro: $settlementsEuro, ')
          ..write('horizonMonths: $horizonMonths, ')
          ..write('noticeDate: $noticeDate, ')
          ..write('kuendigungsArt: $kuendigungsArt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    situation,
    birthYear,
    taxClass,
    childAllowanceFactor,
    childrenUnder25,
    hasChildForAlg,
    churchMember,
    state,
    healthAdditionalRatePercent,
    grossMonthEuro,
    annualExtrasEuro,
    entryDate,
    regularEndDate,
    severanceGrossEuro,
    exitDate,
    paidRelease,
    settlementsEuro,
    horizonMonths,
    noticeDate,
    kuendigungsArt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WizardState &&
          other.id == this.id &&
          other.situation == this.situation &&
          other.birthYear == this.birthYear &&
          other.taxClass == this.taxClass &&
          other.childAllowanceFactor == this.childAllowanceFactor &&
          other.childrenUnder25 == this.childrenUnder25 &&
          other.hasChildForAlg == this.hasChildForAlg &&
          other.churchMember == this.churchMember &&
          other.state == this.state &&
          other.healthAdditionalRatePercent ==
              this.healthAdditionalRatePercent &&
          other.grossMonthEuro == this.grossMonthEuro &&
          other.annualExtrasEuro == this.annualExtrasEuro &&
          other.entryDate == this.entryDate &&
          other.regularEndDate == this.regularEndDate &&
          other.severanceGrossEuro == this.severanceGrossEuro &&
          other.exitDate == this.exitDate &&
          other.paidRelease == this.paidRelease &&
          other.settlementsEuro == this.settlementsEuro &&
          other.horizonMonths == this.horizonMonths &&
          other.noticeDate == this.noticeDate &&
          other.kuendigungsArt == this.kuendigungsArt);
}

class WizardStatesCompanion extends UpdateCompanion<WizardState> {
  final Value<int> id;
  final Value<int> situation;
  final Value<int> birthYear;
  final Value<int> taxClass;
  final Value<double> childAllowanceFactor;
  final Value<int> childrenUnder25;
  final Value<bool> hasChildForAlg;
  final Value<bool> churchMember;
  final Value<String> state;
  final Value<double> healthAdditionalRatePercent;
  final Value<int> grossMonthEuro;
  final Value<int> annualExtrasEuro;
  final Value<DateTime> entryDate;
  final Value<DateTime> regularEndDate;
  final Value<int> severanceGrossEuro;
  final Value<DateTime> exitDate;
  final Value<bool> paidRelease;
  final Value<int> settlementsEuro;
  final Value<int> horizonMonths;
  final Value<DateTime> noticeDate;
  final Value<int> kuendigungsArt;
  const WizardStatesCompanion({
    this.id = const Value.absent(),
    this.situation = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.taxClass = const Value.absent(),
    this.childAllowanceFactor = const Value.absent(),
    this.childrenUnder25 = const Value.absent(),
    this.hasChildForAlg = const Value.absent(),
    this.churchMember = const Value.absent(),
    this.state = const Value.absent(),
    this.healthAdditionalRatePercent = const Value.absent(),
    this.grossMonthEuro = const Value.absent(),
    this.annualExtrasEuro = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.regularEndDate = const Value.absent(),
    this.severanceGrossEuro = const Value.absent(),
    this.exitDate = const Value.absent(),
    this.paidRelease = const Value.absent(),
    this.settlementsEuro = const Value.absent(),
    this.horizonMonths = const Value.absent(),
    this.noticeDate = const Value.absent(),
    this.kuendigungsArt = const Value.absent(),
  });
  WizardStatesCompanion.insert({
    this.id = const Value.absent(),
    required int situation,
    required int birthYear,
    required int taxClass,
    required double childAllowanceFactor,
    required int childrenUnder25,
    required bool hasChildForAlg,
    required bool churchMember,
    required String state,
    required double healthAdditionalRatePercent,
    required int grossMonthEuro,
    required int annualExtrasEuro,
    required DateTime entryDate,
    required DateTime regularEndDate,
    required int severanceGrossEuro,
    required DateTime exitDate,
    required bool paidRelease,
    required int settlementsEuro,
    required int horizonMonths,
    required DateTime noticeDate,
    this.kuendigungsArt = const Value.absent(),
  }) : situation = Value(situation),
       birthYear = Value(birthYear),
       taxClass = Value(taxClass),
       childAllowanceFactor = Value(childAllowanceFactor),
       childrenUnder25 = Value(childrenUnder25),
       hasChildForAlg = Value(hasChildForAlg),
       churchMember = Value(churchMember),
       state = Value(state),
       healthAdditionalRatePercent = Value(healthAdditionalRatePercent),
       grossMonthEuro = Value(grossMonthEuro),
       annualExtrasEuro = Value(annualExtrasEuro),
       entryDate = Value(entryDate),
       regularEndDate = Value(regularEndDate),
       severanceGrossEuro = Value(severanceGrossEuro),
       exitDate = Value(exitDate),
       paidRelease = Value(paidRelease),
       settlementsEuro = Value(settlementsEuro),
       horizonMonths = Value(horizonMonths),
       noticeDate = Value(noticeDate);
  static Insertable<WizardState> custom({
    Expression<int>? id,
    Expression<int>? situation,
    Expression<int>? birthYear,
    Expression<int>? taxClass,
    Expression<double>? childAllowanceFactor,
    Expression<int>? childrenUnder25,
    Expression<bool>? hasChildForAlg,
    Expression<bool>? churchMember,
    Expression<String>? state,
    Expression<double>? healthAdditionalRatePercent,
    Expression<int>? grossMonthEuro,
    Expression<int>? annualExtrasEuro,
    Expression<DateTime>? entryDate,
    Expression<DateTime>? regularEndDate,
    Expression<int>? severanceGrossEuro,
    Expression<DateTime>? exitDate,
    Expression<bool>? paidRelease,
    Expression<int>? settlementsEuro,
    Expression<int>? horizonMonths,
    Expression<DateTime>? noticeDate,
    Expression<int>? kuendigungsArt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (situation != null) 'situation': situation,
      if (birthYear != null) 'birth_year': birthYear,
      if (taxClass != null) 'tax_class': taxClass,
      if (childAllowanceFactor != null)
        'child_allowance_factor': childAllowanceFactor,
      if (childrenUnder25 != null) 'children_under25': childrenUnder25,
      if (hasChildForAlg != null) 'has_child_for_alg': hasChildForAlg,
      if (churchMember != null) 'church_member': churchMember,
      if (state != null) 'state': state,
      if (healthAdditionalRatePercent != null)
        'health_additional_rate_percent': healthAdditionalRatePercent,
      if (grossMonthEuro != null) 'gross_month_euro': grossMonthEuro,
      if (annualExtrasEuro != null) 'annual_extras_euro': annualExtrasEuro,
      if (entryDate != null) 'entry_date': entryDate,
      if (regularEndDate != null) 'regular_end_date': regularEndDate,
      if (severanceGrossEuro != null)
        'severance_gross_euro': severanceGrossEuro,
      if (exitDate != null) 'exit_date': exitDate,
      if (paidRelease != null) 'paid_release': paidRelease,
      if (settlementsEuro != null) 'settlements_euro': settlementsEuro,
      if (horizonMonths != null) 'horizon_months': horizonMonths,
      if (noticeDate != null) 'notice_date': noticeDate,
      if (kuendigungsArt != null) 'kuendigungs_art': kuendigungsArt,
    });
  }

  WizardStatesCompanion copyWith({
    Value<int>? id,
    Value<int>? situation,
    Value<int>? birthYear,
    Value<int>? taxClass,
    Value<double>? childAllowanceFactor,
    Value<int>? childrenUnder25,
    Value<bool>? hasChildForAlg,
    Value<bool>? churchMember,
    Value<String>? state,
    Value<double>? healthAdditionalRatePercent,
    Value<int>? grossMonthEuro,
    Value<int>? annualExtrasEuro,
    Value<DateTime>? entryDate,
    Value<DateTime>? regularEndDate,
    Value<int>? severanceGrossEuro,
    Value<DateTime>? exitDate,
    Value<bool>? paidRelease,
    Value<int>? settlementsEuro,
    Value<int>? horizonMonths,
    Value<DateTime>? noticeDate,
    Value<int>? kuendigungsArt,
  }) {
    return WizardStatesCompanion(
      id: id ?? this.id,
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
      noticeDate: noticeDate ?? this.noticeDate,
      kuendigungsArt: kuendigungsArt ?? this.kuendigungsArt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (situation.present) {
      map['situation'] = Variable<int>(situation.value);
    }
    if (birthYear.present) {
      map['birth_year'] = Variable<int>(birthYear.value);
    }
    if (taxClass.present) {
      map['tax_class'] = Variable<int>(taxClass.value);
    }
    if (childAllowanceFactor.present) {
      map['child_allowance_factor'] = Variable<double>(
        childAllowanceFactor.value,
      );
    }
    if (childrenUnder25.present) {
      map['children_under25'] = Variable<int>(childrenUnder25.value);
    }
    if (hasChildForAlg.present) {
      map['has_child_for_alg'] = Variable<bool>(hasChildForAlg.value);
    }
    if (churchMember.present) {
      map['church_member'] = Variable<bool>(churchMember.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (healthAdditionalRatePercent.present) {
      map['health_additional_rate_percent'] = Variable<double>(
        healthAdditionalRatePercent.value,
      );
    }
    if (grossMonthEuro.present) {
      map['gross_month_euro'] = Variable<int>(grossMonthEuro.value);
    }
    if (annualExtrasEuro.present) {
      map['annual_extras_euro'] = Variable<int>(annualExtrasEuro.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<DateTime>(entryDate.value);
    }
    if (regularEndDate.present) {
      map['regular_end_date'] = Variable<DateTime>(regularEndDate.value);
    }
    if (severanceGrossEuro.present) {
      map['severance_gross_euro'] = Variable<int>(severanceGrossEuro.value);
    }
    if (exitDate.present) {
      map['exit_date'] = Variable<DateTime>(exitDate.value);
    }
    if (paidRelease.present) {
      map['paid_release'] = Variable<bool>(paidRelease.value);
    }
    if (settlementsEuro.present) {
      map['settlements_euro'] = Variable<int>(settlementsEuro.value);
    }
    if (horizonMonths.present) {
      map['horizon_months'] = Variable<int>(horizonMonths.value);
    }
    if (noticeDate.present) {
      map['notice_date'] = Variable<DateTime>(noticeDate.value);
    }
    if (kuendigungsArt.present) {
      map['kuendigungs_art'] = Variable<int>(kuendigungsArt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WizardStatesCompanion(')
          ..write('id: $id, ')
          ..write('situation: $situation, ')
          ..write('birthYear: $birthYear, ')
          ..write('taxClass: $taxClass, ')
          ..write('childAllowanceFactor: $childAllowanceFactor, ')
          ..write('childrenUnder25: $childrenUnder25, ')
          ..write('hasChildForAlg: $hasChildForAlg, ')
          ..write('churchMember: $churchMember, ')
          ..write('state: $state, ')
          ..write('healthAdditionalRatePercent: $healthAdditionalRatePercent, ')
          ..write('grossMonthEuro: $grossMonthEuro, ')
          ..write('annualExtrasEuro: $annualExtrasEuro, ')
          ..write('entryDate: $entryDate, ')
          ..write('regularEndDate: $regularEndDate, ')
          ..write('severanceGrossEuro: $severanceGrossEuro, ')
          ..write('exitDate: $exitDate, ')
          ..write('paidRelease: $paidRelease, ')
          ..write('settlementsEuro: $settlementsEuro, ')
          ..write('horizonMonths: $horizonMonths, ')
          ..write('noticeDate: $noticeDate, ')
          ..write('kuendigungsArt: $kuendigungsArt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WizardStatesTable wizardStates = $WizardStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [wizardStates];
}

typedef $$WizardStatesTableCreateCompanionBuilder =
    WizardStatesCompanion Function({
      Value<int> id,
      required int situation,
      required int birthYear,
      required int taxClass,
      required double childAllowanceFactor,
      required int childrenUnder25,
      required bool hasChildForAlg,
      required bool churchMember,
      required String state,
      required double healthAdditionalRatePercent,
      required int grossMonthEuro,
      required int annualExtrasEuro,
      required DateTime entryDate,
      required DateTime regularEndDate,
      required int severanceGrossEuro,
      required DateTime exitDate,
      required bool paidRelease,
      required int settlementsEuro,
      required int horizonMonths,
      required DateTime noticeDate,
      Value<int> kuendigungsArt,
    });
typedef $$WizardStatesTableUpdateCompanionBuilder =
    WizardStatesCompanion Function({
      Value<int> id,
      Value<int> situation,
      Value<int> birthYear,
      Value<int> taxClass,
      Value<double> childAllowanceFactor,
      Value<int> childrenUnder25,
      Value<bool> hasChildForAlg,
      Value<bool> churchMember,
      Value<String> state,
      Value<double> healthAdditionalRatePercent,
      Value<int> grossMonthEuro,
      Value<int> annualExtrasEuro,
      Value<DateTime> entryDate,
      Value<DateTime> regularEndDate,
      Value<int> severanceGrossEuro,
      Value<DateTime> exitDate,
      Value<bool> paidRelease,
      Value<int> settlementsEuro,
      Value<int> horizonMonths,
      Value<DateTime> noticeDate,
      Value<int> kuendigungsArt,
    });

class $$WizardStatesTableFilterComposer
    extends Composer<_$AppDatabase, $WizardStatesTable> {
  $$WizardStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get situation => $composableBuilder(
    column: $table.situation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxClass => $composableBuilder(
    column: $table.taxClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get childAllowanceFactor => $composableBuilder(
    column: $table.childAllowanceFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get childrenUnder25 => $composableBuilder(
    column: $table.childrenUnder25,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasChildForAlg => $composableBuilder(
    column: $table.hasChildForAlg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get churchMember => $composableBuilder(
    column: $table.churchMember,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get healthAdditionalRatePercent => $composableBuilder(
    column: $table.healthAdditionalRatePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grossMonthEuro => $composableBuilder(
    column: $table.grossMonthEuro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get annualExtrasEuro => $composableBuilder(
    column: $table.annualExtrasEuro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get regularEndDate => $composableBuilder(
    column: $table.regularEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get severanceGrossEuro => $composableBuilder(
    column: $table.severanceGrossEuro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get exitDate => $composableBuilder(
    column: $table.exitDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paidRelease => $composableBuilder(
    column: $table.paidRelease,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get settlementsEuro => $composableBuilder(
    column: $table.settlementsEuro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get horizonMonths => $composableBuilder(
    column: $table.horizonMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get noticeDate => $composableBuilder(
    column: $table.noticeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kuendigungsArt => $composableBuilder(
    column: $table.kuendigungsArt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WizardStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WizardStatesTable> {
  $$WizardStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get situation => $composableBuilder(
    column: $table.situation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxClass => $composableBuilder(
    column: $table.taxClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get childAllowanceFactor => $composableBuilder(
    column: $table.childAllowanceFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get childrenUnder25 => $composableBuilder(
    column: $table.childrenUnder25,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasChildForAlg => $composableBuilder(
    column: $table.hasChildForAlg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get churchMember => $composableBuilder(
    column: $table.churchMember,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get healthAdditionalRatePercent => $composableBuilder(
    column: $table.healthAdditionalRatePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grossMonthEuro => $composableBuilder(
    column: $table.grossMonthEuro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get annualExtrasEuro => $composableBuilder(
    column: $table.annualExtrasEuro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get regularEndDate => $composableBuilder(
    column: $table.regularEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get severanceGrossEuro => $composableBuilder(
    column: $table.severanceGrossEuro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get exitDate => $composableBuilder(
    column: $table.exitDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paidRelease => $composableBuilder(
    column: $table.paidRelease,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get settlementsEuro => $composableBuilder(
    column: $table.settlementsEuro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get horizonMonths => $composableBuilder(
    column: $table.horizonMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get noticeDate => $composableBuilder(
    column: $table.noticeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kuendigungsArt => $composableBuilder(
    column: $table.kuendigungsArt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WizardStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WizardStatesTable> {
  $$WizardStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get situation =>
      $composableBuilder(column: $table.situation, builder: (column) => column);

  GeneratedColumn<int> get birthYear =>
      $composableBuilder(column: $table.birthYear, builder: (column) => column);

  GeneratedColumn<int> get taxClass =>
      $composableBuilder(column: $table.taxClass, builder: (column) => column);

  GeneratedColumn<double> get childAllowanceFactor => $composableBuilder(
    column: $table.childAllowanceFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get childrenUnder25 => $composableBuilder(
    column: $table.childrenUnder25,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasChildForAlg => $composableBuilder(
    column: $table.hasChildForAlg,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get churchMember => $composableBuilder(
    column: $table.churchMember,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<double> get healthAdditionalRatePercent => $composableBuilder(
    column: $table.healthAdditionalRatePercent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grossMonthEuro => $composableBuilder(
    column: $table.grossMonthEuro,
    builder: (column) => column,
  );

  GeneratedColumn<int> get annualExtrasEuro => $composableBuilder(
    column: $table.annualExtrasEuro,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumn<DateTime> get regularEndDate => $composableBuilder(
    column: $table.regularEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get severanceGrossEuro => $composableBuilder(
    column: $table.severanceGrossEuro,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get exitDate =>
      $composableBuilder(column: $table.exitDate, builder: (column) => column);

  GeneratedColumn<bool> get paidRelease => $composableBuilder(
    column: $table.paidRelease,
    builder: (column) => column,
  );

  GeneratedColumn<int> get settlementsEuro => $composableBuilder(
    column: $table.settlementsEuro,
    builder: (column) => column,
  );

  GeneratedColumn<int> get horizonMonths => $composableBuilder(
    column: $table.horizonMonths,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get noticeDate => $composableBuilder(
    column: $table.noticeDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kuendigungsArt => $composableBuilder(
    column: $table.kuendigungsArt,
    builder: (column) => column,
  );
}

class $$WizardStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WizardStatesTable,
          WizardState,
          $$WizardStatesTableFilterComposer,
          $$WizardStatesTableOrderingComposer,
          $$WizardStatesTableAnnotationComposer,
          $$WizardStatesTableCreateCompanionBuilder,
          $$WizardStatesTableUpdateCompanionBuilder,
          (
            WizardState,
            BaseReferences<_$AppDatabase, $WizardStatesTable, WizardState>,
          ),
          WizardState,
          PrefetchHooks Function()
        > {
  $$WizardStatesTableTableManager(_$AppDatabase db, $WizardStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WizardStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WizardStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WizardStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> situation = const Value.absent(),
                Value<int> birthYear = const Value.absent(),
                Value<int> taxClass = const Value.absent(),
                Value<double> childAllowanceFactor = const Value.absent(),
                Value<int> childrenUnder25 = const Value.absent(),
                Value<bool> hasChildForAlg = const Value.absent(),
                Value<bool> churchMember = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<double> healthAdditionalRatePercent =
                    const Value.absent(),
                Value<int> grossMonthEuro = const Value.absent(),
                Value<int> annualExtrasEuro = const Value.absent(),
                Value<DateTime> entryDate = const Value.absent(),
                Value<DateTime> regularEndDate = const Value.absent(),
                Value<int> severanceGrossEuro = const Value.absent(),
                Value<DateTime> exitDate = const Value.absent(),
                Value<bool> paidRelease = const Value.absent(),
                Value<int> settlementsEuro = const Value.absent(),
                Value<int> horizonMonths = const Value.absent(),
                Value<DateTime> noticeDate = const Value.absent(),
                Value<int> kuendigungsArt = const Value.absent(),
              }) => WizardStatesCompanion(
                id: id,
                situation: situation,
                birthYear: birthYear,
                taxClass: taxClass,
                childAllowanceFactor: childAllowanceFactor,
                childrenUnder25: childrenUnder25,
                hasChildForAlg: hasChildForAlg,
                churchMember: churchMember,
                state: state,
                healthAdditionalRatePercent: healthAdditionalRatePercent,
                grossMonthEuro: grossMonthEuro,
                annualExtrasEuro: annualExtrasEuro,
                entryDate: entryDate,
                regularEndDate: regularEndDate,
                severanceGrossEuro: severanceGrossEuro,
                exitDate: exitDate,
                paidRelease: paidRelease,
                settlementsEuro: settlementsEuro,
                horizonMonths: horizonMonths,
                noticeDate: noticeDate,
                kuendigungsArt: kuendigungsArt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int situation,
                required int birthYear,
                required int taxClass,
                required double childAllowanceFactor,
                required int childrenUnder25,
                required bool hasChildForAlg,
                required bool churchMember,
                required String state,
                required double healthAdditionalRatePercent,
                required int grossMonthEuro,
                required int annualExtrasEuro,
                required DateTime entryDate,
                required DateTime regularEndDate,
                required int severanceGrossEuro,
                required DateTime exitDate,
                required bool paidRelease,
                required int settlementsEuro,
                required int horizonMonths,
                required DateTime noticeDate,
                Value<int> kuendigungsArt = const Value.absent(),
              }) => WizardStatesCompanion.insert(
                id: id,
                situation: situation,
                birthYear: birthYear,
                taxClass: taxClass,
                childAllowanceFactor: childAllowanceFactor,
                childrenUnder25: childrenUnder25,
                hasChildForAlg: hasChildForAlg,
                churchMember: churchMember,
                state: state,
                healthAdditionalRatePercent: healthAdditionalRatePercent,
                grossMonthEuro: grossMonthEuro,
                annualExtrasEuro: annualExtrasEuro,
                entryDate: entryDate,
                regularEndDate: regularEndDate,
                severanceGrossEuro: severanceGrossEuro,
                exitDate: exitDate,
                paidRelease: paidRelease,
                settlementsEuro: settlementsEuro,
                horizonMonths: horizonMonths,
                noticeDate: noticeDate,
                kuendigungsArt: kuendigungsArt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WizardStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WizardStatesTable,
      WizardState,
      $$WizardStatesTableFilterComposer,
      $$WizardStatesTableOrderingComposer,
      $$WizardStatesTableAnnotationComposer,
      $$WizardStatesTableCreateCompanionBuilder,
      $$WizardStatesTableUpdateCompanionBuilder,
      (
        WizardState,
        BaseReferences<_$AppDatabase, $WizardStatesTable, WizardState>,
      ),
      WizardState,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WizardStatesTableTableManager get wizardStates =>
      $$WizardStatesTableTableManager(_db, _db.wizardStates);
}
