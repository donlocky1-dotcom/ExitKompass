import 'dart:convert';

import 'package:exitkompass_app/coach/coach_engine.dart';
import 'package:exitkompass_app/coach/gemini_coach_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('posts the conversation to the proxy and parses the reply', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({'reply': 'Gute Antwort! Nächste Frage: Was reizt dich?'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final engine = GeminiCoachEngine(
      endpoint: 'https://proxy.example/coach',
      entitlementToken: 'user-123',
      client: client,
    );

    final reply = await engine.reply([
      CoachMessage(CoachRole.coach, engine.opening(CoachPersona.hart)),
      const CoachMessage(CoachRole.user, 'Meine Antwort.'),
    ], CoachPersona.hart);

    expect(reply, contains('Nächste Frage'));
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['mode'], 'interview');
    expect(body['personaPrompt'], contains('hart'));
    expect((body['messages'] as List).last['role'], 'user');
    expect(captured.headers['authorization'], 'Bearer user-123');
    expect(engine.label, 'Gemini Flash');
  });

  test('a 402 from the proxy returns a premium hint', () async {
    final client =
        MockClient((req) async => http.Response('{"error":"not_entitled"}', 402));
    final engine =
        GeminiCoachEngine(endpoint: 'https://proxy.example/coach', client: client);
    final reply = await engine.reply(
        [const CoachMessage(CoachRole.user, 'Hallo')], CoachPersona.neutral);
    expect(reply, contains('Premium'));
  });
}
