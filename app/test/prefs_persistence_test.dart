import 'package:exitkompass_app/state/application_docs.dart';
import 'package:exitkompass_app/state/intake.dart';
import 'package:exitkompass_app/state/prefs_stores.dart';
import 'package:exitkompass_app/state/wizard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty());

  test('wizard inputs survive save + reload', () async {
    await WizardPrefsStore().save(WizardData(
      grossMonthEuro: 7777,
      kuendigungsArt: KuendigungsArt.betriebsbedingt,
      severanceGrossEuro: 33000,
    ));
    final loaded = await WizardPrefsStore.load();
    expect(loaded, isNotNull);
    expect(loaded!.grossMonthEuro, 7777);
    expect(loaded.kuendigungsArt, KuendigungsArt.betriebsbedingt);
    expect(loaded.severanceGrossEuro, 33000);
  });

  test('workbook answers survive save + reload', () async {
    final store = WorkbookPrefsStore();
    await store.save('q1', 'Antwort 1');
    await store.save('q2', 'Antwort 2');
    await store.save('q1', ''); // empty removes it
    expect(await WorkbookPrefsStore.load(), {'q2': 'Antwort 2'});
  });

  test('CV and job ad survive save + reload', () async {
    ApplicationDocsController()
      ..setCv(text: 'Mein Lebenslauf', fileName: 'cv.pdf')
      ..setJobAd('Data Engineer gesucht');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final loaded = await loadApplicationDocs();
    expect(loaded.cvText, 'Mein Lebenslauf');
    expect(loaded.jobAdText, 'Data Engineer gesucht');
    expect(loaded.cvFileName, 'cv.pdf');
  });

  test('intake choice survives save + reload', () async {
    IntakeController().complete(goal: StartGoal.verhandeln);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final loaded = await loadIntake();
    expect(loaded.done, isTrue);
    expect(loaded.goal, StartGoal.verhandeln);
  });
}
