import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lt/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('line events arriving out of order merge into one row', () async {
    await db.createSession(id: 's1', sourceLang: 'en', targetLang: 'my');
    await db.createLine('s1', 'seg_0', 1200);
    await db.updateLine('s1', 'seg_0', const LinesCompanion(translatedText: Value('မင်္ဂလာပါ')));
    await db.updateLine('s1', 'seg_0', const LinesCompanion(originalText: Value('Hello')));

    final lines = await db.watchLines('s1').first;
    expect(lines, hasLength(1));
    expect(lines.single.originalText, 'Hello');
    expect(lines.single.translatedText, 'မင်္ဂလာပါ');
  });

  test('updating a deleted line is a no-op', () async {
    await db.createSession(id: 's1', sourceLang: 'en', targetLang: 'my');
    await db.createLine('s1', 'seg_0', 0);
    await db.deleteLine('s1', 'seg_0');
    await db.updateLine('s1', 'seg_0', const LinesCompanion(endMs: Value(500)));

    expect(await db.linesFor('s1'), isEmpty);
  });

  test('deleting a session removes its lines', () async {
    await db.createSession(id: 's1', sourceLang: 'en', targetLang: 'my');
    await db.createLine('s1', 'seg_0', 0);
    await db.deleteSession('s1');

    expect(await db.select(db.lines).get(), isEmpty);
  });

  test('unfinished sessions are found for crash recovery', () async {
    await db.createSession(id: 's1', sourceLang: 'en', targetLang: 'my');
    await db.createSession(id: 's2', sourceLang: 'en', targetLang: 'my');
    await db.updateSession('s2', const SessionsCompanion(status: Value(SessionStatus.complete)));

    final unfinished = await db.unfinishedSessions();
    expect(unfinished.map((s) => s.id), ['s1']);
  });
}
