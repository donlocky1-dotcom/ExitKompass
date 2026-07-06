import 'package:exitkompass_app/widgets/help_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: ListView(children: [child])),
    );

void main() {
  testWidgets('panel is collapsed and shows the no-ads promise', (tester) async {
    await tester.pumpWidget(_host(const HelpPanel(flagCodes: {})));

    expect(find.text('Passende Hilfe finden'), findsOneWidget);
    expect(find.textContaining('keine Werbung, keine Vermittlung'), findsOneWidget);
  });

  testWidgets('expanding reveals resources; a match is pinned first',
      (tester) async {
    await tester.pumpWidget(_host(const HelpPanel(flagCodes: {'kv_luecke'})));

    await tester.tap(find.text('Passende Hilfe finden'));
    await tester.pumpAndSettle();

    // The health-insurance entry is surfaced by the kv_luecke flag.
    expect(find.text('Krankenversicherung klären'), findsOneWidget);
    expect(find.text('Fachanwalt für Arbeitsrecht'), findsOneWidget);
  });

  testWidgets('tapping a resource opens its detail with source and disclaimer',
      (tester) async {
    await tester.pumpWidget(_host(const HelpPanel(flagCodes: {'kv_luecke'})));

    await tester.tap(find.text('Passende Hilfe finden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Krankenversicherung klären'));
    await tester.pumpAndSettle();

    expect(find.text('Wo du dich hinwenden kannst'), findsOneWidget);
    expect(find.text('§ 188 SGB V'), findsOneWidget);
    // Mandatory disclaimer footer is present on the detail screen.
    expect(find.textContaining('keine Steuer- oder'), findsOneWidget);
  });
}
