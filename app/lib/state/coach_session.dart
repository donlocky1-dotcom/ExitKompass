import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../coach/coach_engine.dart';

/// A paused/ongoing coaching conversation. Persisted locally (via
/// shared_preferences → localStorage on the web) so it survives leaving the
/// coach screen, reloading the page or restarting the app. Cleared on
/// "Daten löschen". The disclaimer asks the user not to enter sensitive data.
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

  Map<String, dynamic> toJson() => {
        'persona': persona.name,
        'messages': [
          for (final m in messages)
            {
              'role': m.role == CoachRole.user ? 'user' : 'coach',
              'text': m.text,
            },
        ],
      };

  static CoachSession fromJson(CoachMode mode, Map<String, dynamic> json) {
    return CoachSession(
      mode: mode,
      persona: CoachPersona.values.firstWhere(
        (p) => p.name == json['persona'],
        orElse: () => CoachPersona.neutral,
      ),
      messages: [
        for (final m in (json['messages'] as List? ?? const []))
          CoachMessage(
            (m as Map)['role'] == 'user' ? CoachRole.user : CoachRole.coach,
            m['text'] as String? ?? '',
          ),
      ],
    );
  }
}

const _kCoachSessionsKey = 'coach_sessions_v1';

/// Loads the persisted conversations. Call once at startup (see main).
Future<Map<CoachMode, CoachSession>> loadCoachSessions() async {
  try {
    final raw = await SharedPreferencesAsync().getString(_kCoachSessionsKey);
    if (raw == null) return const {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final out = <CoachMode, CoachSession>{};
    for (final entry in decoded.entries) {
      final matches = CoachMode.values.where((m) => m.name == entry.key);
      if (matches.isEmpty) continue;
      out[matches.first] =
          CoachSession.fromJson(matches.first, entry.value as Map<String, dynamic>);
    }
    return out;
  } catch (_) {
    return const {};
  }
}

/// Ongoing conversations, one per mode, so switching Bewerbung ↔ Verhandlung
/// (or leaving and returning) keeps each conversation intact. Every change is
/// written back to local storage.
class CoachSessionController extends StateNotifier<Map<CoachMode, CoachSession>> {
  CoachSessionController({Map<CoachMode, CoachSession>? initial})
      : super(initial ?? const {});

  void save(CoachSession session) {
    state = {...state, session.mode: session};
    _persist();
  }

  void clear() {
    state = const {};
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = SharedPreferencesAsync();
      final snapshot = state;
      if (snapshot.isEmpty) {
        await prefs.remove(_kCoachSessionsKey);
        return;
      }
      final encoded = {
        for (final entry in snapshot.entries) entry.key.name: entry.value.toJson(),
      };
      await prefs.setString(_kCoachSessionsKey, jsonEncode(encoded));
    } catch (_) {
      // Best effort – persistence must never break the chat.
    }
  }
}

final coachSessionProvider =
    StateNotifierProvider<CoachSessionController, Map<CoachMode, CoachSession>>(
        (ref) => CoachSessionController());
