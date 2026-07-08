import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'coach_engine.dart';
import 'mock_coach_engine.dart';

/// The active coaching engine. Defaults to the local preview; can be
/// overridden (e.g. in main.dart) with a Gemini-backed engine once the
/// premium proxy is in place.
final coachEngineProvider = Provider<CoachEngine>((ref) => MockCoachEngine());
