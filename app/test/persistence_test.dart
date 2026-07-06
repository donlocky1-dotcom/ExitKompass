import 'dart:io';

import 'package:drift/native.dart';
import 'package:exit_engine/exit_engine.dart';
import 'package:exitkompass_app/data/app_database.dart';
import 'package:exitkompass_app/data/wizard_repository.dart';
import 'package:exitkompass_app/state/wizard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WizardRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WizardRepository(db);
  });

  tearDown(() => db.close());

  test('load() returns null when nothing has been saved', () async {
    expect(await repo.load(), isNull);
  });

  test('save() then load() round-trips every field', () async {
    final original = WizardData(
      situation: Situation.aufhebungAngeboten,
      birthYear: 1979,
      taxClass: TaxClass.iii,
      childAllowanceFactor: 2,
      childrenUnder25: 2,
      hasChildForAlg: true,
      churchMember: true,
      state: Bundesland.bayern,
      healthAdditionalRatePercent: 1.7,
      grossMonthEuro: 7500,
      annualExtrasEuro: 5000,
      entryDate: DateTime(2011, 3, 1),
      regularEndDate: DateTime(2026, 9, 30),
      severanceGrossEuro: 90000,
      exitDate: DateTime(2026, 6, 30),
      paidRelease: true,
      settlementsEuro: 3000,
      horizonMonths: 36,
      kuendigungsArt: KuendigungsArt.betriebsbedingt,
      monthlyExpensesEuro: 3200,
      savingsEuro: 25000,
      noticeDate: DateTime(2026, 4, 15),
    );

    await repo.save(original);
    final loaded = await repo.load();

    expect(loaded, isNotNull);
    expect(loaded!.situation, original.situation);
    expect(loaded.birthYear, original.birthYear);
    expect(loaded.taxClass, original.taxClass);
    expect(loaded.childAllowanceFactor, original.childAllowanceFactor);
    expect(loaded.childrenUnder25, original.childrenUnder25);
    expect(loaded.hasChildForAlg, original.hasChildForAlg);
    expect(loaded.churchMember, original.churchMember);
    expect(loaded.state, original.state);
    expect(loaded.healthAdditionalRatePercent, original.healthAdditionalRatePercent);
    expect(loaded.grossMonthEuro, original.grossMonthEuro);
    expect(loaded.annualExtrasEuro, original.annualExtrasEuro);
    expect(loaded.entryDate, original.entryDate);
    expect(loaded.regularEndDate, original.regularEndDate);
    expect(loaded.severanceGrossEuro, original.severanceGrossEuro);
    expect(loaded.exitDate, original.exitDate);
    expect(loaded.paidRelease, original.paidRelease);
    expect(loaded.settlementsEuro, original.settlementsEuro);
    expect(loaded.horizonMonths, original.horizonMonths);
    expect(loaded.kuendigungsArt, original.kuendigungsArt);
    expect(loaded.monthlyExpensesEuro, original.monthlyExpensesEuro);
    expect(loaded.savingsEuro, original.savingsEuro);
    expect(loaded.noticeDate, original.noticeDate);
  });

  test('save() upserts the single row (no duplicates)', () async {
    await repo.save(WizardData(grossMonthEuro: 4000));
    await repo.save(WizardData(grossMonthEuro: 6000));
    final rows = await db.select(db.wizardStates).get();
    expect(rows, hasLength(1));
    expect((await repo.load())!.grossMonthEuro, 6000);
  });

  test('clear() removes the saved state', () async {
    await repo.save(WizardData(grossMonthEuro: 5000));
    await repo.clear();
    expect(await repo.load(), isNull);
  });

  test('migration from v1 re-adds all later columns and preserves data', () async {
    final dir = await Directory.systemTemp.createTemp('exitkompass_mig1');
    final file = File('${dir.path}/db.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // 1) Create a current database and save a row.
    final current = AppDatabase(NativeDatabase(file));
    await WizardRepository(current).save(WizardData(
      grossMonthEuro: 6100,
      kuendigungsArt: KuendigungsArt.verhaltensbedingt,
      monthlyExpensesEuro: 3300,
      savingsEuro: 27000,
    ));
    await current.close();

    // 2) Downgrade the file to look like schema v1: drop every column added
    //    after v1 and reset the schema version.
    final raw = AppDatabase(NativeDatabase(file));
    await raw.customStatement('ALTER TABLE wizard_states DROP COLUMN kuendigungs_art');
    await raw.customStatement('ALTER TABLE wizard_states DROP COLUMN monthly_expenses_euro');
    await raw.customStatement('ALTER TABLE wizard_states DROP COLUMN savings_euro');
    await raw.customStatement('PRAGMA user_version = 1');
    await raw.close();

    // 3) Reopen → onUpgrade(1→3) re-adds all columns with their defaults.
    final upgraded = AppDatabase(NativeDatabase(file));
    final loaded = await WizardRepository(upgraded).load();
    expect(loaded, isNotNull);
    expect(loaded!.grossMonthEuro, 6100, reason: 'existing data preserved');
    expect(loaded.kuendigungsArt, KuendigungsArt.unbekannt);
    expect(loaded.monthlyExpensesEuro, 2500, reason: 'v3 default');
    expect(loaded.savingsEuro, 10000, reason: 'v3 default');
    await upgraded.close();
  });

  test('migration v2→v3 adds the bridge columns and preserves data', () async {
    final dir = await Directory.systemTemp.createTemp('exitkompass_mig2');
    final file = File('${dir.path}/db.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // 1) Save with the current schema (v3).
    final current = AppDatabase(NativeDatabase(file));
    await WizardRepository(current).save(WizardData(
      grossMonthEuro: 6200,
      kuendigungsArt: KuendigungsArt.betriebsbedingt,
      monthlyExpensesEuro: 4000,
      savingsEuro: 50000,
    ));
    await current.close();

    // 2) Downgrade to v2: drop only the v3 columns, keep kuendigungs_art.
    final raw = AppDatabase(NativeDatabase(file));
    await raw.customStatement('ALTER TABLE wizard_states DROP COLUMN monthly_expenses_euro');
    await raw.customStatement('ALTER TABLE wizard_states DROP COLUMN savings_euro');
    await raw.customStatement('PRAGMA user_version = 2');
    await raw.close();

    // 3) Reopen → onUpgrade(2→3) adds the bridge columns; other data stays.
    final upgraded = AppDatabase(NativeDatabase(file));
    final loaded = await WizardRepository(upgraded).load();
    expect(loaded, isNotNull);
    expect(loaded!.grossMonthEuro, 6200, reason: 'existing data preserved');
    expect(loaded.kuendigungsArt, KuendigungsArt.betriebsbedingt,
        reason: 'v2 column untouched');
    expect(loaded.monthlyExpensesEuro, 2500, reason: 're-added v3 default');
    expect(loaded.savingsEuro, 10000, reason: 're-added v3 default');
    await upgraded.close();
  });

  test('a controller with a repository persists updates', () async {
    final controller = WizardController(repository: repo);
    controller.update((d) => d.copyWith(severanceGrossEuro: 42000));
    // Give the async save a chance to complete.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await repo.load())!.severanceGrossEuro, 42000);

    await controller.clearSaved();
    expect(await repo.load(), isNull);
  });
}
