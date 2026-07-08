/// Abstraction over the conversational coaching backend.
///
/// The local preview ([MockCoachEngine]) scripts an interview from the
/// existing question bank and needs no network, key or cost. A Gemini-backed
/// engine (called through the premium proxy) can drop in later behind this
/// same interface without touching the chat UI.
library;

enum CoachRole { coach, user }

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

  /// The coach's opening line that starts a fresh session.
  String opening();

  /// The coach's next reply given the whole conversation so far. The last
  /// entry in [history] is the user's most recent message.
  Future<String> reply(List<CoachMessage> history);
}
