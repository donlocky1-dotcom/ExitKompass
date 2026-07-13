import 'package:exitkompass_app/content/bewerbung.dart';
import 'package:exitkompass_app/screens/bewerbung_screen.dart';
import 'package:exitkompass_app/state/workbook.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bewerbung content integrity', () {
    test('question ids (texts) are unique', () {
      final ids = interviewQuestions.map((q) => q.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

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

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: BewerbungScreen()),
    ));
    await tester.pumpAndSettle();

    // These render as iOS-style uppercased section labels.
    expect(find.text('Die STAR-Methode'.toUpperCase()), findsOneWidget);
    expect(find.text('Workbook als PDF'.toUpperCase()), findsOneWidget);
    expect(find.text('Leeres Workbook'), findsOneWidget);
    expect(find.text('Ausgefülltes Workbook'), findsOneWidget);
    expect(find.text('Grundhaltung: Verkauf dich über deinen Wert'), findsOneWidget);
    expect(find.text('Fragen, die DU stellst'), findsOneWidget);

    // Expand a question to reveal its "So gehst du ran" block and the
    // persisted workbook answer field.
    await tester.tap(find.textContaining('Erzählen Sie etwas über sich'));
    await tester.pumpAndSettle();
    expect(find.text('So gehst du ran'), findsWidgets);
    expect(find.text('Deine Antwort (wird lokal gespeichert)'), findsWidgets);

    // Typing into the workbook field must keep the text and save it (the
    // field must not clobber input by reassigning its controller on rebuild).
    final field = find.byType(TextField).first;
    await tester.enterText(field, 'Meine Übungsantwort');
    await tester.pump();
    expect(find.text('Meine Übungsantwort'), findsOneWidget);

    final container = ProviderScope.containerOf(
        tester.element(find.byType(BewerbungScreen)));
    expect(container.read(workbookProvider).values,
        contains('Meine Übungsantwort'));
  });
}
