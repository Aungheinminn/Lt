import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Sessions, Lines])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(sessions, sessions.mode);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'history',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  Stream<List<Session>> watchSessions() {
    return (select(sessions)
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .watch();
  }

  Stream<Session?> watchSession(String id) {
    return (select(sessions)..where((s) => s.id.equals(id)))
        .watchSingleOrNull();
  }

  Stream<List<Line>> watchLines(String sessionId) {
    return (select(lines)
          ..where((l) => l.sessionId.equals(sessionId))
          ..orderBy([(l) => OrderingTerm.asc(l.startMs)]))
        .watch();
  }

  Future<void> createSession({
    required String id,
    required String sourceLang,
    required String targetLang,
    SessionMode mode = SessionMode.captions,
    String? audioPath,
  }) {
    return into(sessions).insert(SessionsCompanion.insert(
      id: id,
      sourceLang: sourceLang,
      targetLang: targetLang,
      createdAt: DateTime.now(),
      status: SessionStatus.recording,
      mode: Value(mode),
      audioPath: Value(audioPath),
    ));
  }

  Future<void> updateSession(String id, SessionsCompanion changes) {
    return (update(sessions)..where((s) => s.id.equals(id))).write(changes);
  }

  Future<void> deleteSession(String id) {
    return (delete(sessions)..where((s) => s.id.equals(id))).go();
  }

  Future<void> createLine(String sessionId, String itemId, int startMs) {
    return into(lines).insert(LinesCompanion.insert(
      sessionId: sessionId,
      itemId: itemId,
      startMs: startMs,
    ));
  }

  /// Merges [data] into an existing line. A line that was already deleted
  /// (e.g. discarded as noise) is left alone.
  Future<void> updateLine(String sessionId, String itemId, LinesCompanion data) {
    return (update(lines)
          ..where((l) => l.sessionId.equals(sessionId) & l.itemId.equals(itemId)))
        .write(data);
  }

  Future<void> deleteLine(String sessionId, String itemId) {
    return (delete(lines)
          ..where((l) => l.sessionId.equals(sessionId) & l.itemId.equals(itemId)))
        .go();
  }

  Future<List<Line>> linesFor(String sessionId) {
    return (select(lines)
          ..where((l) => l.sessionId.equals(sessionId))
          ..orderBy([(l) => OrderingTerm.asc(l.startMs)]))
        .get();
  }

  /// Sessions left in `recording` or `finalizing` mean the app was killed
  /// mid-session.
  Future<List<Session>> unfinishedSessions() {
    return (select(sessions)
          ..where((s) => s.status.isIn([
                SessionStatus.recording.name,
                SessionStatus.finalizing.name,
              ])))
        .get();
  }
}
