import 'package:exitkompass_app/screens/vacation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('vacation calculator shows the payout and pro-rata helper',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: VacationScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Abgeltung gesamt'), findsOneWidget);
    expect(find.text('Wert pro Urlaubstag'), findsOneWidget);

    // Change the open days and expect the payout to react (10 → 20 days).
    final daysField = find.ancestor(
      of: find.text('Offene Urlaubstage'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(daysField, '20');
    await tester.pumpAndSettle();

    // Expand the pro-rata helper.
    await tester.tap(find.text('Wie viele Tage stehen mir anteilig zu?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Anteiliger Anspruch'), findsOneWidget);
  });
}
