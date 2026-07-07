import 'package:exitkompass_app/screens/non_compete_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('non-compete calculator shows the 50% minimum and reacts to input',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: NonCompeteScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Mindest-Entschädigung / Monat (50 %)'), findsOneWidget);
    // Default salary 5000 → 2.500 € minimum shown somewhere.
    expect(find.textContaining('2.500'), findsWidgets);

    // Enter a duration beyond two years → the § 74a warning appears.
    final durationField = find.ancestor(
      of: find.text('Dauer des Verbots (Monate)'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(durationField, '30');
    await tester.pumpAndSettle();
    expect(find.textContaining('höchstens zwei Jahre'), findsOneWidget);
  });
}
