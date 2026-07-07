import 'package:drift/drift.dart';

import 'app_database.dart';

/// Loads and saves the user's Bewerbungstraining workbook answers to the
/// local Drift/SQLite database, keyed by the interview question's id.
class WorkbookRepository {
  WorkbookRepository(this._db);

  final AppDatabase _db;

  /// All saved answers as a map questionId → answer.
  Future<Map<String, String>> loadAll() async {
    final rows = await _db.select(_db.workbookAnswers).get();
    return {for (final r in rows) r.questionId: r.answer};
  }

  /// Upserts one answer. An empty answer is removed to keep the table tidy.
  Future<void> save(String questionId, String answer) async {
    if (answer.isEmpty) {
      await (_db.delete(_db.workbookAnswers)
            ..where((t) => t.questionId.equals(questionId)))
          .go();
      return;
    }
    await _db.into(_db.workbookAnswers).insertOnConflictUpdate(
          WorkbookAnswersCompanion.insert(
            questionId: questionId,
            answer: Value(answer),
          ),
        );
  }

  /// Deletes all saved answers (spec §13: "Daten vollständig löschen").
  Future<void> clear() => _db.delete(_db.workbookAnswers).go();
}
