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
      CoachMessage(CoachRole.coach,
          engine.opening(CoachMode.interview, CoachPersona.hart)),
      const CoachMessage(CoachRole.user, 'Meine Antwort.'),
    ], CoachMode.interview, CoachPersona.hart);

    expect(reply, contains('Nächste Frage'));
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['system'], contains('"Sie"')); // formal register
    expect(body['system'], contains('hart')); // persona modifier
    expect((body['messages'] as List).last['role'], 'user');
    expect(captured.headers['authorization'], 'Bearer user-123');
    expect(engine.label, 'Gemini Flash');
  });

  test('negotiation mode sends the negotiation prompt and context figures',
      () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({'reply': 'Zunächst käme nur der untere Bereich in Frage.'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final engine = GeminiCoachEngine(
      endpoint: 'https://proxy.example/coach',
      client: client,
    );

    final reply = await engine.reply(
      [const CoachMessage(CoachRole.user, 'Ich möchte 60.000 €.')],
      CoachMode.negotiation,
      CoachPersona.neutral,
      contextNote: '- Verhandelbare Abfindungs-Bandbreite: 20.000 € bis 40.000 €',
    );

    expect(reply, isNotEmpty);
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['system'], contains('Abfindungs')); // negotiation base prompt
    expect(body['system'], contains('Bandbreite')); // context note injected
  });

  test('a 402 from the proxy returns a premium hint', () async {
    final client =
        MockClient((req) async => http.Response('{"error":"not_entitled"}', 402));
    final engine =
        GeminiCoachEngine(endpoint: 'https://proxy.example/coach', client: client);
    final reply = await engine.reply(
        [const CoachMessage(CoachRole.user, 'Hallo')],
        CoachMode.interview,
        CoachPersona.neutral);
    expect(reply, contains('Premium'));
  });

  test('extractDocument uploads the file as base64 inline data', () async {
    late http.Request captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response(
        jsonEncode({'reply': 'Berufliche Stationen: Data Engineer …'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final engine =
        GeminiCoachEngine(endpoint: 'https://proxy.example/coach', client: client);

    final text = await engine.extractDocument(
      const CoachAttachment(
          bytes: [37, 80, 68, 70], mimeType: 'application/pdf', name: 'cv.pdf'),
    );

    expect(text, contains('Data Engineer'));
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['system'], contains('Lebenslauf')); // extraction prompt
    final file = (body['messages'] as List).first['files'][0] as Map;
    expect(file['mimeType'], 'application/pdf');
    expect(file['data'], base64Encode([37, 80, 68, 70]));
  });
}
