import 'package:exitkompass_app/coach/coach_engine.dart';
import 'package:exitkompass_app/coach/mock_coach_engine.dart';
import 'package:exitkompass_app/screens/unterlagen_screen.dart';
import 'package:exitkompass_app/state/application_docs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApplicationDocs', () {
    test('isReady only once CV and job ad are both present', () {
      const empty = ApplicationDocs();
      expect(empty.isReady, isFalse);
      expect(empty.copyWith(jobAdText: 'Stelle').isReady, isFalse);
      final ready = empty.copyWith(jobAdText: 'Stelle', cvText: 'CV');
      expect(ready.isReady, isTrue);
    });

    test('buildDocsContext carries both documents labelled', () {
      const docs = ApplicationDocs(
        jobAdText: 'Data Engineer mit Python',
        cvText: '5 Jahre Python, SQL',
        cvFileName: 'cv.pdf',
      );
      final ctx = buildDocsContext(docs);
      expect(ctx, contains('Stellenanzeige:'));
      expect(ctx, contains('Data Engineer mit Python'));
      expect(ctx, contains('Lebenslauf'));
      expect(ctx, contains('5 Jahre Python, SQL'));
    });
  });

  group('MockCoachEngine documents mode', () {
    test('extractDocument returns a preview placeholder naming the file',
        () async {
      final engine = MockCoachEngine();
      final text = await engine.extractDocument(
        const CoachAttachment(bytes: [1, 2, 3], mimeType: 'application/pdf', name: 'cv.pdf'),
      );
      expect(text, contains('cv.pdf'));
    });

    test('reply in documents mode returns the structured analysis shape',
        () async {
      final engine = MockCoachEngine();
      final reply = await engine.reply(
        const [CoachMessage(CoachRole.user, 'Analysiere bitte.')],
        CoachMode.unterlagen,
        CoachPersona.neutral,
        contextNote: 'Stellenanzeige: X\nLebenslauf: Y',
      );
      expect(reply, contains('Passung'));
      expect(reply, contains('Tipps'));
    });
  });

  testWidgets('UnterlagenScreen enables analysis and shows the result',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applicationDocsProvider.overrideWith((ref) {
            final c = ApplicationDocsController()
              ..setJobAd('Wir suchen Data Engineer, Python & SQL.')
              ..setCv(text: '5 Jahre Python, SQL, ETL', fileName: 'cv.pdf');
            return c;
          }),
        ],
        child: const MaterialApp(home: UnterlagenScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stellenanzeige'), findsOneWidget);
    expect(find.text('Lebenslauf'), findsOneWidget);

    await tester.tap(find.text('Analysieren'));
    await tester.pumpAndSettle();

    // Mock engine returns the structured analysis preview.
    expect(find.textContaining('Passung'), findsWidgets);
  });
}
