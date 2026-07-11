import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coach/coach_engine.dart';

/// A paused/ongoing coaching conversation, kept in memory so leaving the coach
/// screen and coming back resumes it. Not written to disk (privacy – the chat
/// can contain personal input); cleared on "Daten löschen".
class CoachSession {
  const CoachSession({
    required this.messages,
    required this.mode,
    required this.persona,
  });

  final List<CoachMessage> messages;
  final CoachMode mode;
  final CoachPersona persona;

  /// True once the user has actually said something worth resuming.
  bool get hasUserTurns => messages.any((m) => m.role == CoachRole.user);
}

/// Ongoing conversations, one per mode, so switching Bewerbung ↔ Verhandlung
/// (or leaving and returning) keeps each conversation intact.
class CoachSessionController extends StateNotifier<Map<CoachMode, CoachSession>> {
  CoachSessionController() : super(const {});

  void save(CoachSession session) =>
      state = {...state, session.mode: session};

  void clear() => state = const {};
}

final coachSessionProvider =
    StateNotifierProvider<CoachSessionController, Map<CoachMode, CoachSession>>(
        (ref) => CoachSessionController());
