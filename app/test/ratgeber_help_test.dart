import 'package:exitkompass_app/screens/ratgeber_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A tall surface so the whole (lazy) article ListView, including the
  // trailing help panel, is built without scrolling.
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .views.first;
    view.physicalSize = const Size(1200, 6000);
    view.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('the info-only Ratgeber screen surfaces the help panel',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RatgeberScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Passende Hilfe finden'), findsOneWidget);
  });

  testWidgets('the plain Ratgeber tab (HomeShell) does not duplicate the panel',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RatgeberTab())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Passende Hilfe finden'), findsNothing);
  });
}
