import 'package:exitkompass_app/main.dart';
import 'package:exitkompass_app/screens/quick_estimate_screen.dart';
import 'package:exitkompass_app/screens/wizard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding leads into the quick estimate, which shows a range',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: ExitKompassApp()));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loslegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Abfindung')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Schnell-Check'));
    await tester.tap(find.text('Schnell-Check'));
    await tester.pumpAndSettle();

    expect(find.byType(QuickEstimateScreen), findsOneWidget);
    expect(find.textContaining('Realistische Bandbreite'), findsOneWidget);
  });

  testWidgets('the quick estimate carries into the detailed wizard', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: ExitKompassApp()));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loslegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Abfindung')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Schnell-Check'));
    await tester.tap(find.text('Schnell-Check'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Detaillierten Netto-Vergleich starten'));
    await tester.tap(find.text('Detaillierten Netto-Vergleich starten'));
    await tester.pumpAndSettle();

    expect(find.byType(WizardScreen), findsOneWidget);
  });
}
