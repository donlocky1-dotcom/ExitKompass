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
  String opening(CoachMode mode, CoachPersona persona) {
    final who = persona.label.toLowerCase();
    if (mode == CoachMode.unterlagen) {
      return 'Unterlagen-Check (Vorschau). Fügen Sie die Stellenanzeige ein und '
          'laden Sie Ihren Lebenslauf hoch – mit dem KI-Coach vergleiche ich '
          'beides und gebe konkrete Tipps.';
    }
    if (mode == CoachMode.negotiation) {
      return 'Willkommen zur Verhandlungs-Simulation (Vorschau, $who). Ich '
          'spiele die Personalleitung im Abfindungsgespräch. Wie steigen Sie '
          'ein?';
    }
    return 'Willkommen zur Gesprächssimulation. Ich spiele die interviewende '
        'Person ($who) – antworten Sie einfach, wie Sie es im echten Gespräch '
        'täten. Am besten mit der STAR-Struktur (Situation · Aufgabe · '
        'Handlung · Ergebnis).\n\nLos geht’s:\n${_questions.first.question}';
  }

  @override
  Future<String> extractDocument(CoachAttachment attachment) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // The offline preview cannot read files – the real extraction runs on the
    // Gemini engine. Return a clear placeholder so the flow still works.
    return 'Lebenslauf „${attachment.name.isEmpty ? 'Datei' : attachment.name}" '
        'hochgeladen (Vorschau – ohne KI wird der Inhalt nicht ausgelesen). '
        'Mit dem KI-Coach im Premium wird der Lebenslauf hier automatisch als '
        'Text erfasst.';
  }

  @override
  Future<String> reply(
    List<CoachMessage> history,
    CoachMode mode,
    CoachPersona persona, {
    String contextNote = '',
  }) async {
    // Small delay so the UI shows a natural "typing" beat.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (mode == CoachMode.unterlagen) return _documentsReply();
    if (mode == CoachMode.negotiation) return _negotiationReply(history);

    final userTurns = history.where((m) => m.role == CoachRole.user).length;
    final answeredIndex = (userTurns - 1).clamp(0, _questions.length - 1);
    final tip = _feedbackFor(_questions[answeredIndex]);

    final nextIndex = userTurns;
    if (nextIndex >= _questions.length) {
      return '$tip\n\nDas war die letzte Übungsfrage – gut gemacht! Gehen Sie '
          'die Fragen gern noch einmal durch und formulieren Sie Ihre Antworten '
          'mit konkreten Ergebnissen (STAR) noch knackiger.';
    }
    return '$tip\n\nNächste Frage:\n${_questions[nextIndex].question}';
  }

  String _feedbackFor(InterviewQuestion q) {
    final tip = q.tips.isNotEmpty ? ' ${q.tips.first}' : '';
    return '💡 Tipp zu dieser Frage: ${q.approach}$tip';
  }

  /// Offline stand-in for the document review (the real comparison runs on the
  /// Gemini engine; this preview only shows the shape of the result).
  String _documentsReply() {
    return '1. Passung: Vorschau ohne KI – hier erscheint eine kurze '
        'Einschätzung, wie gut Ihr Lebenslauf zur Stelle passt.\n\n'
        '2. Passende Stärken: die Punkte aus Ihrem Lebenslauf, die zu den '
        'Anforderungen passen.\n\n'
        '3. Lücken & Risiken: fehlende Anforderungen und wie Sie sie '
        'ansprechen.\n\n'
        '4. Tipps fürs Gespräch: was Sie betonen und vorbereiten sollten.\n\n'
        '(Mit dem KI-Coach im Premium wird dieser Abgleich automatisch aus '
        'Ihren echten Unterlagen erstellt.)';
  }

  /// Minimal offline stand-in for the negotiation (the real dynamic partner
  /// is the Gemini engine; this preview only shows the flow).
  String _negotiationReply(List<CoachMessage> history) {
    final userTurns = history.where((m) => m.role == CoachRole.user).length;
    switch (userTurns) {
      case 1:
        return 'Danke. Aus unserer Sicht käme zunächst nur eine Abfindung im '
            'unteren Bereich in Frage. Womit begründen Sie eine höhere Summe?';
      case 2:
        return 'Das ist ein Argument. Ein Teil davon ließe sich womöglich '
            'darstellen – was wäre für Sie das Minimum, mit dem Sie zustimmen '
            'würden?';
      default:
        return 'Gut verhandelt. (Vorschau ohne KI – mit dem KI-Coach reagiert '
            'die Gegenseite dynamisch auf Ihre Argumente.)';
    }
  }
}
