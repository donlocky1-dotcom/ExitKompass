import 'dart:convert';

import 'package:http/http.dart' as http;

import 'coach_engine.dart';

/// Coaching engine backed by Gemini Flash **through the premium proxy**.
///
/// The app never talks to Gemini directly and never holds an API key: it
/// posts the conversation to the Cloudflare Worker proxy (see `/worker`),
/// which checks the premium entitlement, injects the system prompt and the
/// key, calls Gemini and returns the reply. Wiring is inert until an
/// [endpoint] is configured (see [coachEngineProvider]); nothing goes live
/// by default.
class GeminiCoachEngine implements CoachEngine {
  GeminiCoachEngine({
    required this.endpoint,
    this.entitlementToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Full URL of the proxy's coach endpoint, e.g.
  /// `https://exitkompass-coach.<account>.workers.dev/coach`.
  final String endpoint;

  /// Optional bearer token proving the premium entitlement (e.g. the
  /// RevenueCat app user id / a signed token). The proxy verifies it.
  final String? entitlementToken;

  final http.Client _client;

  @override
  String get label => 'Gemini Flash';

  @override
  bool get isAiPowered => true;

  @override
  String opening() =>
      'Willkommen zur Gesprächssimulation. Ich spiele die interviewende '
      'Person und stelle dir nacheinander Fragen. Antworte, wie du es im '
      'echten Gespräch tätest – am besten mit der STAR-Struktur.\n\n'
      'Los geht’s: Erzähl mir kurz etwas über dich.';

  @override
  Future<String> reply(List<CoachMessage> history) async {
    final http.Response res;
    try {
      res = await _client.post(
        Uri.parse(endpoint),
        headers: {
          'content-type': 'application/json',
          if (entitlementToken != null)
            'authorization': 'Bearer $entitlementToken',
        },
        body: jsonEncode({
          'mode': 'interview',
          'messages': [
            for (final m in history)
              {'role': m.role == CoachRole.user ? 'user' : 'coach', 'text': m.text},
          ],
        }),
      );
    } catch (_) {
      return 'Der KI-Coach ist gerade nicht erreichbar (Verbindungsproblem). '
          'Prüfe deine Internetverbindung und versuch es noch einmal.';
    }

    if (res.statusCode == 402 || res.statusCode == 403) {
      return 'Der KI-Coach ist Teil von Premium. Bitte schalte Premium frei, '
          'um die KI-gestützte Simulation zu nutzen.';
    }
    if (res.statusCode != 200) {
      return 'Der KI-Coach ist gerade nicht erreichbar (Fehler '
          '${res.statusCode}). Versuch es später noch einmal.';
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final reply = (data['reply'] as String?)?.trim();
    if (reply == null || reply.isEmpty) {
      return 'Ich habe gerade keine Antwort erhalten. Formulier deine Antwort '
          'gern noch einmal.';
    }
    return reply;
  }
}
