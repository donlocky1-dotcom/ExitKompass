import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workbook_repository.dart';

/// Holds the user's own Bewerbungstraining answers (questionId → answer).
/// When a [WorkbookRepository] is provided, every change is persisted.
class WorkbookController extends StateNotifier<Map<String, String>> {
  WorkbookController({WorkbookRepository? repository, Map<String, String>? initial})
      // ignore: prefer_initializing_formals
      : _repository = repository,
        super(initial ?? const {});

  final WorkbookRepository? _repository;

  String answerFor(String questionId) => state[questionId] ?? '';

  void setAnswer(String questionId, String answer) {
    state = {...state, questionId: answer};
    _repository?.save(questionId, answer);
  }

  /// Resets all answers and deletes them from storage
  /// (spec §13: "Daten vollständig löschen").
  Future<void> clearSaved() async {
    state = const {};
    await _repository?.clear();
  }
}

final workbookProvider =
    StateNotifierProvider<WorkbookController, Map<String, String>>(
        (ref) => WorkbookController());
