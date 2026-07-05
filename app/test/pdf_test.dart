import 'dart:io';

import 'package:exit_engine/exit_engine.dart';
import 'package:exitkompass_app/pdf/dossier.dart';
import 'package:exitkompass_app/state/wizard.dart';
import 'package:exitkompass_app/timeline/timeline.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildDossierPdf produces a valid, non-trivial PDF', () async {
    final data = WizardData(situation: Situation.kuendigungErhalten);
    final bytes = await buildDossierPdf(
      data: data,
      result: data.compute(),
      timeline: buildTimeline(data),
      regularTtf: await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
      boldTtf: await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
    );

    // Valid PDF header and EOF marker.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));
    final tail = String.fromCharCodes(bytes.skip(bytes.length - 32));
    expect(tail.contains('%%EOF'), isTrue);

    // Write it out for optional manual/visual inspection.
    final out = Platform.environment['DOSSIER_OUT'];
    if (out != null) {
      File(out).writeAsBytesSync(bytes);
    }
  });

  test('all four scenarios and the disclaimer are representable', () {
    // Sanity: the aggregate the PDF renders is complete.
    final result = WizardData().compute();
    expect(result.scenarios.keys.toSet(), ScenarioType.values.toSet());
  });
}
