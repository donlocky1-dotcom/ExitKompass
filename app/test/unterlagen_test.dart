import 'package:exitkompass_app/coach/coach_engine.dart';
import 'package:exitkompass_app/coach/mock_coach_engine.dart';
import 'package:exitkompass_app/screens/unterlagen_screen.dart';
import 'package:exitkompass_app/state/application_docs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty());

  group('ApplicationDocs', () {
    test('isReadyForCoach only once CV and a selected job ad are present', () {
      const empty = ApplicationDocs();
      expect(empty.isReadyForCoach, isFalse);
      final withAd = empty.copyWith(
        profiles: const [
          JobProfile(id: 'p1', title: 'Stelle', jobAdText: 'Stelle'),
        ],
        selectedProfileId: 'p1',
      );
      expect(withAd.isReadyForCoach, isFalse); // CV still missing
      expect(withAd.copyWith(cvText: 'CV').isReadyForCoach, isTrue);
    });

    test('buildDocsContext carries both documents labelled', () {
      final ctx = buildDocsContext(
        cvText: '5 Jahre Python, SQL',
        jobAdText: 'Data Engineer mit Python',
      );
      expect(ctx, contains('Stellenanzeige:'));
      expect(ctx, contains('Data Engineer mit Python'));
      expect(ctx, contains('Lebenslauf'));
      expect(ctx, contains('5 Jahre Python, SQL'));
    });

    test('legacy single-job-ad JSON migrates into one profile', () {
      final docs = ApplicationDocs.fromJson({
        'cv': 'Mein CV',
        'cvFile': 'cv.pdf',
        'jobAd': 'Alte Stelle',
      });
      expect(docs.profiles, hasLength(1));
      expect(docs.selected!.jobAdText, 'Alte Stelle');
      expect(docs.cvText, 'Mein CV');
      expect(docs.selectedProfileId, docs.profiles.first.id);
    });

    test('controller adds, selects and deletes profiles', () {
      final c = ApplicationDocsController();
      final a = c.addProfile(title: 'Stelle A');
      final b = c.addProfile(title: 'Stelle B');
      expect(c.state.profiles, hasLength(2));
      expect(c.state.selectedProfileId, b); // the newest is selected

      c.selectProfile(a);
      expect(c.state.selected!.id, a);

      c.deleteProfile(a);
      expect(c.state.profiles, hasLength(1));
      expect(c.state.selected!.id, b); // selection falls back to remaining
    });
  });

  group('MockCoachEngine documents mode', () {
    test('extractDocument returns a preview placeholder naming the file',
        () async {
      final engine = MockCoachEngine();
      final text = await engine.extractDocument(
        const CoachAttachment(
            bytes: [1, 2, 3], mimeType: 'application/pdf', name: 'cv.pdf'),
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
    // Tall viewport so the whole scrollable form is laid out at once.
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applicationDocsProvider.overrideWith((ref) {
            final c = ApplicationDocsController();
            final id = c.addProfile(title: 'Data Engineer');
            c.updateProfile(id, jobAdText: 'Wir suchen Data Engineer, Python.');
            c.setCv(text: '5 Jahre Python, SQL, ETL', fileName: 'cv.pdf');
            return c;
          }),
        ],
        child: const MaterialApp(home: UnterlagenScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Section headers render as iOS-style uppercased labels.
    expect(find.text('Stellenanzeige'.toUpperCase()), findsOneWidget);
    expect(find.text('Lebenslauf'.toUpperCase()), findsOneWidget);

    final analyze = find.text('Analysieren');
    await tester.ensureVisible(analyze);
    await tester.pumpAndSettle();
    await tester.tap(analyze);
    await tester.pumpAndSettle();

    // Mock engine returns the structured analysis preview.
    expect(find.textContaining('Passung'), findsWidgets);
  });
}
