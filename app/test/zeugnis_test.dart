import 'package:exitkompass_app/coach/coach_engine.dart';
import 'package:exitkompass_app/coach/mock_coach_engine.dart';
import 'package:exitkompass_app/content/zeugnis.dart';
import 'package:exitkompass_app/screens/zeugnis_decoder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Zeugnis content integrity', () {
    test('every phrase has text and a meaning', () {
      for (final p in zeugnisPhrases) {
        expect(p.phrase, isNotEmpty);
        expect(p.meaning, isNotEmpty);
      }
    });

    test('grades, where set, are in the 1..6 school range', () {
      for (final p in zeugnisPhrases) {
        if (p.grade != null) {
          expect(p.grade, inInclusiveRange(1, 6), reason: p.phrase);
        }
      }
    });

    test('the six performance grades are all covered', () {
      final grades = zeugnisPhrases
          .where((p) => p.category == ZeugnisCategory.leistung)
          .map((p) => p.grade)
          .toSet();
      expect(grades, containsAll([1, 2, 3, 4, 5, 6]));
    });

    test('a review date is set', () {
      expect(zeugnisReviewedOn, isNotEmpty);
    });

    test('MockCoachEngine analyzeZeugnis returns the graded shape', () async {
      final reply = await MockCoachEngine().analyzeZeugnis(
        const CoachAttachment(
            bytes: [1, 2, 3], mimeType: 'image/jpeg', name: 'zeugnis.jpg'),
      );
      expect(reply, contains('Gesamtnote'));
      expect(reply, contains('zeugnis.jpg'));
    });
  });

  testWidgets('decoder screen renders the scale and a grade badge', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: ZeugnisDecoderScreen())));
    await tester.pumpAndSettle();

    // Category headers render as iOS-style uppercased section labels.
    expect(find.text('Leistungsbeurteilung'.toUpperCase()), findsOneWidget);
    expect(find.textContaining('stets zu unserer vollsten Zufriedenheit'), findsOneWidget);
    // The "sehr gut" grade badge shows a "1".
    expect(find.text('1'), findsWidgets);
    expect(find.textContaining('§ 109 GewO'), findsOneWidget);
  });
}
