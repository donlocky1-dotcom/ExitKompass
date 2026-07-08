/// Abstraction over the conversational coaching backend.
///
/// The local preview ([MockCoachEngine]) scripts an interview from the
/// existing question bank and needs no network, key or cost. A Gemini-backed
/// engine (called through the premium proxy) can drop in later behind this
/// same interface without touching the chat UI.
library;

enum CoachRole { coach, user }

/// The character the AI plays as the conversation partner. Only the flavour
/// changes – the safety guardrails always stay in place (server-side).
enum CoachPersona { freundlich, neutral, hart }

extension CoachPersonaX on CoachPersona {
  String get label => switch (this) {
        CoachPersona.freundlich => 'Freundlich',
        CoachPersona.neutral => 'Neutral',
        CoachPersona.hart => 'Hart',
      };

  /// Short one-liner for the selector.
  String get description => switch (this) {
        CoachPersona.freundlich => 'ermutigend & geduldig',
        CoachPersona.neutral => 'sachlich & professionell',
        CoachPersona.hart => 'fordernd, spielt auf hart',
      };

  /// The instruction appended to the system prompt to shape the character.
  String get promptText => switch (this) {
        CoachPersona.freundlich =>
          'Tritt betont freundlich, ermutigend und geduldig auf. Lobe Gutes, '
              'formuliere Kritik sanft und aufbauend.',
        CoachPersona.neutral =>
          'Tritt sachlich und neutral-professionell auf, wie in einem normalen '
              'strukturierten Gespräch.',
        CoachPersona.hart =>
          'Tritt fordernd und kritisch auf und spiele "auf hart": hake bei '
              'schwachen oder oberflächlichen Antworten nach, hinterfrage '
              'Widersprüche und gib dich nicht schnell zufrieden. Bleib dabei '
              'fair und respektvoll – niemals beleidigend.',
      };
}

/// One turn in the coaching conversation.
class CoachMessage {
  const CoachMessage(this.role, this.text);

  final CoachRole role;
  final String text;
}

/// A pluggable coaching engine.
abstract class CoachEngine {
  /// Short human label for the active backend (shown as a badge).
  String get label;

  /// Whether replies come from a cloud AI (true) or the local preview (false).
  /// Drives the disclaimer copy (data leaves the device only when true).
  bool get isAiPowered;

  /// The coach's opening line that starts a fresh session in the given
  /// [persona].
  String opening(CoachPersona persona);

  /// The coach's next reply given the whole conversation so far and the
  /// active [persona]. The last entry in [history] is the user's most recent
  /// message.
  Future<String> reply(List<CoachMessage> history, CoachPersona persona);
}
