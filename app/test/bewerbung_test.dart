import 'package:exitkompass_app/content/bewerbung.dart';
import 'package:exitkompass_app/screens/bewerbung_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bewerbung content integrity', () {
    test('every question has an approach', () {
      for (final q in interviewQuestions) {
        expect(q.question, isNotEmpty);
        expect(q.approach, isNotEmpty);
      }
    });

    test('every category is represented by at least one question', () {
      final cats = interviewQuestions.map((q) => q.category).toSet();
      expect(cats, InterviewCategory.values.toSet());
    });

    test('a review date and the STAR explainer are set', () {
      expect(bewerbungReviewedOn, isNotEmpty);
      expect(starMethodExplainer, contains('STAR'));
    });

    test('value-selling principles have a title and body', () {
      expect(valueSellingPrinciples, isNotEmpty);
      for (final p in valueSellingPrinciples) {
        expect(p.title, isNotEmpty);
        expect(p.body, isNotEmpty);
      }
    });

    test('brainteaser guide has an intro and steps', () {
      expect(brainteaserIntro, isNotEmpty);
      expect(brainteaserSteps, isNotEmpty);
      for (final s in brainteaserSteps) {
        expect(s.title, isNotEmpty);
        expect(s.body, isNotEmpty);
      }
    });
  });

  testWidgets('training screen shows a question and expands its approach',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: BewerbungScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Die STAR-Methode'), findsOneWidget);
    expect(find.text('Grundhaltung: Verkauf dich über deinen Wert'), findsOneWidget);
    expect(find.text('Fragen, die DU stellst'), findsOneWidget);

    // Expand a question to reveal its "So gehst du ran" block.
    await tester.tap(find.textContaining('Erzählen Sie etwas über sich'));
    await tester.pumpAndSettle();
    expect(find.text('So gehst du ran'), findsWidgets);
  });
}
