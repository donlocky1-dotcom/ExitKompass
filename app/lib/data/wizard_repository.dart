import 'package:drift/drift.dart';
import 'package:exit_engine/exit_engine.dart';

import '../state/wizard.dart';
import 'app_database.dart';

/// Loads and saves the wizard inputs to the local Drift/SQLite database.
/// There is exactly one saved state (id = 0).
class WizardRepository {
  WizardRepository(this._db);

  final AppDatabase _db;
  static const _rowId = 0;

  /// Returns the persisted inputs, or `null` if nothing was saved yet.
  Future<WizardData?> load() async {
    final row = await (_db.select(_db.wizardStates)
          ..where((t) => t.id.equals(_rowId)))
        .getSingleOrNull();
    if (row == null) return null;
    return WizardData(
      situation: Situation.values[row.situation],
      birthYear: row.birthYear,
      taxClass: TaxClass.values[row.taxClass],
      childAllowanceFactor: row.childAllowanceFactor,
      childrenUnder25: row.childrenUnder25,
      hasChildForAlg: row.hasChildForAlg,
      churchMember: row.churchMember,
      state: Bundesland.fromCode(row.state),
      healthAdditionalRatePercent: row.healthAdditionalRatePercent,
      grossMonthEuro: row.grossMonthEuro,
      annualExtrasEuro: row.annualExtrasEuro,
      entryDate: row.entryDate,
      regularEndDate: row.regularEndDate,
      severanceGrossEuro: row.severanceGrossEuro,
      exitDate: row.exitDate,
      paidRelease: row.paidRelease,
      settlementsEuro: row.settlementsEuro,
      horizonMonths: row.horizonMonths,
      kuendigungsArt: KuendigungsArt.values[row.kuendigungsArt],
      monthlyExpensesEuro: row.monthlyExpensesEuro,
      savingsEuro: row.savingsEuro,
      noticeDate: row.noticeDate,
    );
  }

  /// Upserts the single saved state.
  Future<void> save(WizardData d) async {
    await _db.into(_db.wizardStates).insertOnConflictUpdate(
          WizardStatesCompanion.insert(
            id: const Value(_rowId),
            situation: d.situation.index,
            birthYear: d.birthYear,
            taxClass: d.taxClass.index,
            childAllowanceFactor: d.childAllowanceFactor,
            childrenUnder25: d.childrenUnder25,
            hasChildForAlg: d.hasChildForAlg,
            churchMember: d.churchMember,
            state: d.state.code,
            healthAdditionalRatePercent: d.healthAdditionalRatePercent,
            grossMonthEuro: d.grossMonthEuro,
            annualExtrasEuro: d.annualExtrasEuro,
            entryDate: d.entryDate,
            regularEndDate: d.regularEndDate,
            severanceGrossEuro: d.severanceGrossEuro,
            exitDate: d.exitDate,
            paidRelease: d.paidRelease,
            settlementsEuro: d.settlementsEuro,
            horizonMonths: d.horizonMonths,
            kuendigungsArt: Value(d.kuendigungsArt.index),
            monthlyExpensesEuro: Value(d.monthlyExpensesEuro),
            savingsEuro: Value(d.savingsEuro),
            noticeDate: d.noticeDate,
          ),
        );
  }

  /// Deletes the saved state (spec §13: "Daten vollständig löschen").
  Future<void> clear() => _db.delete(_db.wizardStates).go();
}
