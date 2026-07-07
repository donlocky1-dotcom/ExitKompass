import 'dart:io';

import 'package:drift/native.dart';
import 'package:exitkompass_app/data/app_database.dart';
import 'package:exitkompass_app/data/workbook_repository.dart';
import 'package:exitkompass_app/state/workbook.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkbookRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WorkbookRepository(db);
  });
  tearDown(() => db.close());

  test('save then loadAll round-trips answers', () async {
    await repo.save('q1', 'Meine Antwort auf Frage 1');
    await repo.save('q2', 'Zweite Antwort');
    final all = await repo.loadAll();
    expect(all, {'q1': 'Meine Antwort auf Frage 1', 'q2': 'Zweite Antwort'});
  });

  test('saving an empty answer removes the row', () async {
    await repo.save('q1', 'etwas');
    await repo.save('q1', '');
    expect(await repo.loadAll(), isEmpty);
  });

  test('clear() removes everything', () async {
    await repo.save('q1', 'a');
    await repo.save('q2', 'b');
    await repo.clear();
    expect(await repo.loadAll(), isEmpty);
  });

  test('controller persists and clears through the repository', () async {
    final c = WorkbookController(repository: repo);
    c.setAnswer('q1', 'hallo');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await repo.loadAll())['q1'], 'hallo');
    expect(c.answerFor('q1'), 'hallo');

    await c.clearSaved();
    expect(await repo.loadAll(), isEmpty);
    expect(c.answerFor('q1'), '');
  });

  test('migration v3→v4 creates the workbook table, wizard data intact', () async {
    final dir = await Directory.systemTemp.createTemp('exitkompass_wb');
    final file = File('${dir.path}/db.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // Current (v4) db: seed a workbook answer, then simulate a v3 file by
    // dropping the workbook table and resetting the version.
    final v4 = AppDatabase(NativeDatabase(file));
    await WorkbookRepository(v4).save('q1', 'bleibt-nicht'); // will be dropped
    await v4.customStatement('DROP TABLE workbook_answers');
    await v4.customStatement('PRAGMA user_version = 3');
    await v4.close();

    // Reopen → onUpgrade(3→4) recreates the table (empty), no crash.
    final upgraded = AppDatabase(NativeDatabase(file));
    final answers = await WorkbookRepository(upgraded).loadAll();
    expect(answers, isEmpty);
    // And it is usable again.
    await WorkbookRepository(upgraded).save('q2', 'neu');
    expect((await WorkbookRepository(upgraded).loadAll())['q2'], 'neu');
    await upgraded.close();
  });
}
