import 'package:exitkompass_app/coach/coach_engine.dart';
import 'package:exitkompass_app/coach/mock_coach_engine.dart';
import 'package:exitkompass_app/screens/coach_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockCoachEngine', () {
    test('opening poses the first interview question and names the persona', () {
      final engine = MockCoachEngine();
      final opening =
          engine.opening(CoachMode.interview, CoachPersona.hart);
      expect(opening, contains('Willkommen zur Gesprächssimulation'));
      expect(opening, contains('hart'));
      expect(engine.label, isNotEmpty);
    });

    test('after an answer it gives a tip and the next question', () async {
      final engine = MockCoachEngine();
      final history = [
        CoachMessage(CoachRole.coach,
            engine.opening(CoachMode.interview, CoachPersona.neutral)),
        const CoachMessage(CoachRole.user, 'Meine Antwort.'),
      ];
      final reply =
          await engine.reply(history, CoachMode.interview, CoachPersona.neutral);
      expect(reply, contains('Tipp zu dieser Frage'));
      expect(reply, contains('Nächste Frage'));
    });

    test('negotiation mode opens as HR and replies in character', () async {
      final engine = MockCoachEngine();
      final opening =
          engine.opening(CoachMode.negotiation, CoachPersona.hart);
      expect(opening, contains('Verhandlungs-Simulation'));

      final history = [
        CoachMessage(CoachRole.coach, opening),
        const CoachMessage(CoachRole.user, 'Ich hätte gern mehr Abfindung.'),
      ];
      final reply = await engine.reply(
          history, CoachMode.negotiation, CoachPersona.hart);
      expect(reply, isNotEmpty);
    });
  });

  testWidgets('CoachScreen shows the opening and round-trips a message',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CoachScreen()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Willkommen zur Gesprächssimulation'),
        findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Das ist meine Antwort.');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Das ist meine Antwort.'), findsOneWidget);
    expect(find.textContaining('Nächste Frage'), findsOneWidget);
  });

  testWidgets('changing the conversation partner keeps the conversation',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CoachScreen())),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Meine erste Antwort.');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Meine erste Antwort.'), findsOneWidget);

    // Switching the partner (tone only) must not wipe the chat.
    await tester.tap(find.text('Freundlich'));
    await tester.pumpAndSettle();
    expect(find.text('Meine erste Antwort.'), findsOneWidget);
  });

  testWidgets('each mode keeps its own conversation when switching',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CoachScreen())),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Bewerbungs-Antwort.');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Bewerbungs-Antwort.'), findsOneWidget);

    // Switch to Verhandlung → a fresh conversation, the other one is hidden.
    await tester.tap(find.text('Verhandlung'));
    await tester.pumpAndSettle();
    expect(find.text('Bewerbungs-Antwort.'), findsNothing);

    // Switch back to Bewerbung → the conversation is restored.
    await tester.tap(find.text('Bewerbung'));
    await tester.pumpAndSettle();
    expect(find.text('Bewerbungs-Antwort.'), findsOneWidget);
  });

  testWidgets('a paused conversation resumes when reopening the coach',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    Widget appWith(Widget home) => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: home),
        );

    await tester.pumpWidget(appWith(const CoachScreen()));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Bitte fortsetzen.');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Leave the coach and open a brand-new CoachScreen (same container).
    await tester.pumpWidget(appWith(const SizedBox.shrink()));
    await tester.pump();
    await tester.pumpWidget(appWith(const CoachScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Bitte fortsetzen.'), findsOneWidget);
  });
}
