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
      final opening = engine.opening(CoachPersona.hart);
      expect(opening, contains('Willkommen zur Gesprächssimulation'));
      expect(opening, contains('hart'));
      expect(engine.label, isNotEmpty);
    });

    test('after an answer it gives a tip and the next question', () async {
      final engine = MockCoachEngine();
      final history = [
        CoachMessage(CoachRole.coach, engine.opening(CoachPersona.neutral)),
        const CoachMessage(CoachRole.user, 'Meine Antwort.'),
      ];
      final reply = await engine.reply(history, CoachPersona.neutral);
      expect(reply, contains('Tipp zu dieser Frage'));
      expect(reply, contains('Nächste Frage'));
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
}
