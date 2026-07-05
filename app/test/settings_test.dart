import 'package:exitkompass_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap() => const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      );

  /// A tall viewport so the whole (lazily-built) ListView is rendered.
  void useTallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('settings screen shows the key sections', (tester) async {
    useTallView(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Parameterjahr'), findsOneWidget);
    expect(find.text('Impressum'), findsOneWidget);
    expect(find.text('Datenschutzerklärung'), findsOneWidget);
    expect(find.text('Gespeicherte Daten löschen'), findsOneWidget);
  });

  testWidgets('legal notes open in a bottom sheet', (tester) async {
    useTallView(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Impressum'));
    await tester.pumpAndSettle();
    expect(find.textContaining('§ 5 DDG'), findsOneWidget);
  });

  testWidgets('clearing data asks for confirmation', (tester) async {
    useTallView(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gespeicherte Daten löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Daten löschen?'), findsOneWidget);

    // Cancelling keeps us on the settings screen.
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
