import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the user wants to get out of the app. Captured at the start to frame
/// the hub.
enum StartGoal { finanzen, verhandeln, bewerbung, informieren }

extension StartGoalX on StartGoal {
  String get label => switch (this) {
        StartGoal.finanzen => 'Herausfinden, was finanziell rausspringt',
        StartGoal.verhandeln => 'Eine faire Abfindung verhandeln',
        StartGoal.bewerbung => 'Mich auf Bewerbungen vorbereiten',
        StartGoal.informieren => 'Mich erst einmal informieren',
      };

  String get short => switch (this) {
        StartGoal.finanzen => 'Finanzen klären',
        StartGoal.verhandeln => 'Abfindung verhandeln',
        StartGoal.bewerbung => 'Bewerbung vorbereiten',
        StartGoal.informieren => 'Informieren',
      };

  IconData get icon => switch (this) {
        StartGoal.finanzen => Icons.insights_outlined,
        StartGoal.verhandeln => Icons.handshake_outlined,
        StartGoal.bewerbung => Icons.record_voice_over_outlined,
        StartGoal.informieren => Icons.menu_book_outlined,
      };
}

/// Result of the short intake: the chosen goal and whether it was completed.
class IntakeState {
  const IntakeState({this.goal, this.done = false});

  final StartGoal? goal;

  /// Until true the hub shows a "tell us about your situation" call to action
  /// instead of numbers the user never confirmed.
  final bool done;

  Map<String, dynamic> toJson() => {'goal': goal?.name, 'done': done};

  static IntakeState fromJson(Map<String, dynamic> j) {
    final name = j['goal'] as String?;
    StartGoal? goal;
    for (final g in StartGoal.values) {
      if (g.name == name) {
        goal = g;
        break;
      }
    }
    return IntakeState(goal: goal, done: j['done'] as bool? ?? false);
  }
}

const _kIntakeKey = 'intake_v1';

/// Loads the persisted intake state. Call once at startup (see main).
Future<IntakeState> loadIntake() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kIntakeKey);
    if (raw == null) return const IntakeState();
    return IntakeState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return const IntakeState();
  }
}

class IntakeController extends StateNotifier<IntakeState> {
  IntakeController({IntakeState? initial}) : super(initial ?? const IntakeState());

  void complete({StartGoal? goal}) {
    state = IntakeState(goal: goal, done: true);
    _persist();
  }

  void clear() {
    state = const IntakeState();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshot = state; // latest state after the await
      if (!snapshot.done && snapshot.goal == null) {
        await prefs.remove(_kIntakeKey);
        return;
      }
      await prefs.setString(_kIntakeKey, jsonEncode(snapshot.toJson()));
    } catch (_) {
      // Best effort.
    }
  }
}

final intakeProvider =
    StateNotifierProvider<IntakeController, IntakeState>(
        (ref) => IntakeController());
