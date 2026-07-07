import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Single-row table holding the persisted wizard inputs (spec §6:
/// UserProfile + EmploymentData + OfferData). ScenarioResult is never
/// persisted – it is recomputed on the fly.
class WizardStates extends Table {
  /// Always 0 – there is exactly one saved state.
  IntColumn get id => integer().withDefault(const Constant(0))();

  IntColumn get situation => integer()();
  IntColumn get birthYear => integer()();
  IntColumn get taxClass => integer()();
  RealColumn get childAllowanceFactor => real()();
  IntColumn get childrenUnder25 => integer()();
  BoolColumn get hasChildForAlg => boolean()();
  BoolColumn get churchMember => boolean()();
  TextColumn get state => text()();
  RealColumn get healthAdditionalRatePercent => real()();
  IntColumn get grossMonthEuro => integer()();
  IntColumn get annualExtrasEuro => integer()();
  DateTimeColumn get entryDate => dateTime()();
  DateTimeColumn get regularEndDate => dateTime()();
  IntColumn get severanceGrossEuro => integer()();
  DateTimeColumn get exitDate => dateTime()();
  BoolColumn get paidRelease => boolean()();
  IntColumn get settlementsEuro => integer()();
  IntColumn get horizonMonths => integer()();
  DateTimeColumn get noticeDate => dateTime()();

  /// Added in schema v2. Default 0 = KuendigungsArt.unbekannt so existing
  /// rows upgrade cleanly.
  IntColumn get kuendigungsArt => integer().withDefault(const Constant(0))();

  /// Added in schema v3 (bridge planner). Whole euros; defaults keep existing
  /// rows valid.
  IntColumn get monthlyExpensesEuro => integer().withDefault(const Constant(2500))();
  IntColumn get savingsEuro => integer().withDefault(const Constant(10000))();

  @override
  Set<Column> get primaryKey => {id};
}

/// The user's own answers in the Bewerbungstraining workbook, keyed by the
/// interview question's stable id. Added in schema v4.
class WorkbookAnswers extends Table {
  TextColumn get questionId => text()();
  TextColumn get answer => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {questionId};
}

@DriftDatabase(tables: [WizardStates, WorkbookAnswers])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'exitkompass'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(wizardStates, wizardStates.kuendigungsArt);
          }
          if (from < 3) {
            await m.addColumn(wizardStates, wizardStates.monthlyExpensesEuro);
            await m.addColumn(wizardStates, wizardStates.savingsEuro);
          }
          if (from < 4) {
            await m.createTable(workbookAnswers);
          }
        },
      );
}
