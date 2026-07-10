import 'package:exit_engine/exit_engine.dart';
import 'package:exitkompass_app/state/wizard.dart';
import 'package:flutter_test/flutter_test.dart';

Set<String> _aufhebungFlags(WizardData data) => data
    .compute()
    .scenarios[ScenarioType.aufhebungsvertrag]!
    .flags
    .map((f) => f.code)
    .toSet();

void main() {
  test('betriebsbedingt lifts the S2 Sperrzeit within the safe harbour', () {
    // Severance within the § 1a corridor (0.5 salaries/year): 5000 × ~11 / 2.
    final data =
        WizardData(kuendigungsArt: KuendigungsArt.betriebsbedingt, severanceGrossEuro: 20000);
    final flags = _aufhebungFlags(data);
    expect(flags, contains('sperrzeit_unwahrscheinlich'));
    expect(flags, isNot(contains('sperrzeit_wahrscheinlich')));
  });

  test('betriebsbedingt + high severance → no Sperrzeit, only a review note', () {
    // Chemical-industry style factor 1.0+ (well above the 0.5 corridor).
    final data =
        WizardData(kuendigungsArt: KuendigungsArt.betriebsbedingt, severanceGrossEuro: 100000);
    final flags = _aufhebungFlags(data);
    expect(flags, contains('sperrzeit_unwahrscheinlich_pruefung'));
    expect(flags, isNot(contains('sperrzeit_wahrscheinlich')));
  });

  test('an unclear ground keeps the S2 Sperrzeit risk', () {
    final data =
        WizardData(kuendigungsArt: KuendigungsArt.unbekannt, severanceGrossEuro: 20000);
    final flags = _aufhebungFlags(data);
    expect(flags, contains('sperrzeit_wahrscheinlich'));
  });

  test('the employer-dismissal scenario never carries a Sperrzeit', () {
    final flags = WizardData(kuendigungsArt: KuendigungsArt.betriebsbedingt)
        .compute()
        .scenarios[ScenarioType.kuendigungAg]!
        .flags
        .map((f) => f.code)
        .toSet();
    expect(flags.any((c) => c.startsWith('sperrzeit')), isFalse);
  });
}
