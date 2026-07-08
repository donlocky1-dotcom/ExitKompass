import '../content/bewerbung.dart';
import 'coach_engine.dart';

/// Local, offline preview coach: scripts an interview from the existing
/// question bank and gives a short, relevant tip after each answer. No
/// network, key or cost – a stand-in until the Gemini-backed engine is wired
/// through the premium proxy.
class MockCoachEngine implements CoachEngine {
  MockCoachEngine();

  /// A curated interview: classics + tricky questions.
  static final List<InterviewQuestion> _questions = interviewQuestions
      .where((q) =>
          q.category == InterviewCategory.klassiker ||
          q.category == InterviewCategory.kritischeFragen)
      .take(6)
      .toList();

  @override
  String get label => 'Vorschau · lokal';

  @override
  bool get isAiPowered => false;

  @override
  String opening(CoachPersona persona) =>
      'Willkommen zur Gesprächssimulation. Ich spiele die interviewende '
      'Person (${persona.label.toLowerCase()}) – antworte einfach, wie du es '
      'im echten Gespräch tätest. Am besten mit der STAR-Struktur '
      '(Situation · Aufgabe · Handlung · Ergebnis).\n\nLos geht’s:\n'
      '${_questions.first.question}';

  @override
  Future<String> reply(List<CoachMessage> history, CoachPersona persona) async {
    // Small delay so the UI shows a natural "typing" beat.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final userTurns = history.where((m) => m.role == CoachRole.user).length;
    final answeredIndex = (userTurns - 1).clamp(0, _questions.length - 1);
    final tip = _feedbackFor(_questions[answeredIndex]);

    final nextIndex = userTurns;
    if (nextIndex >= _questions.length) {
      return '$tip\n\nDas war die letzte Übungsfrage – gut gemacht! Geh die '
          'Fragen gern noch einmal durch und formuliere deine Antworten mit '
          'konkreten Ergebnissen (STAR) noch knackiger.';
    }
    return '$tip\n\nNächste Frage:\n${_questions[nextIndex].question}';
  }

  String _feedbackFor(InterviewQuestion q) {
    final tip = q.tips.isNotEmpty ? ' ${q.tips.first}' : '';
    return '💡 Tipp zu dieser Frage: ${q.approach}$tip';
  }
}
