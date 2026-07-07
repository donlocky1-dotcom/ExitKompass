import 'dart:io';

import 'package:exitkompass_app/pdf/workbook_pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<int>> build({required bool empty, Map<String, String> answers = const {}}) async {
    return buildWorkbookPdf(
      answers: answers,
      empty: empty,
      regularTtf: await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
      boldTtf: await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
    );
  }

  test('empty workbook is a valid, non-trivial PDF', () async {
    final bytes = await build(empty: true);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));
    expect(String.fromCharCodes(bytes.skip(bytes.length - 32)).contains('%%EOF'), isTrue);
  });

  test('filled workbook builds and can be written out for inspection', () async {
    final bytes = await build(
      empty: false,
      answers: const {'Erzählen Sie etwas über sich.': 'Mein 2-Minuten-Pitch …'},
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));

    final out = Platform.environment['WORKBOOK_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
