import 'package:drift/drift.dart';

import '../audio/audio_file_sink.dart';
import '../data/db/app_database.dart';

Future<void> deleteSessionWithAudio(AppDatabase db, Session session) async {
  // Row first: if the app dies before the file goes, the file is only an
  // orphan, never a row pointing at nothing.
  await db.deleteSession(session.id);
  final audio = session.audioPath;
  if (audio != null) await deleteAudioFile(audio);
}

/// Marks sessions the app was killed during as interrupted and repairs their
/// audio files. Empty ones are removed.
Future<void> recoverUnfinishedSessions(AppDatabase db) async {
  for (final s in await db.unfinishedSessions()) {
    final lines = await db.linesFor(s.id);
    if (lines.isEmpty) {
      await deleteSessionWithAudio(db, s);
      continue;
    }
    final audio = s.audioPath;
    final durationMs = audio == null ? null : await repairAudioFile(audio);
    await db.updateSession(
      s.id,
      SessionsCompanion(
        status: const Value(SessionStatus.interrupted),
        durationMs: Value(durationMs ?? lines.last.endMs ?? lines.last.startMs),
        audioPath: Value(durationMs == null ? null : audio),
      ),
    );
  }
}
