import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists the workbook answers. Implemented by the Drift repository (native)
/// and a shared_preferences store (used on the web preview).
abstract class WorkbookStore {
  Future<void> save(String questionId, String answer);
  Future<void> clear();
}

/// Holds the user's own Bewerbungstraining answers (questionId → answer).
/// When a [WorkbookStore] is provided, every change is persisted.
class WorkbookController extends StateNotifier<Map<String, String>> {
  WorkbookController({WorkbookStore? repository, Map<String, String>? initial})
      // ignore: prefer_initializing_formals
      : _repository = repository,
        super(initial ?? const {});

  final WorkbookStore? _repository;

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
