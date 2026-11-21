import 'package:drift/drift.dart';

enum SessionStatus { recording, finalizing, complete, interrupted }

class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant('Untitled session'))();
  TextColumn get sourceLang => text()();
  TextColumn get targetLang => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get status => textEnum<SessionStatus>()();
  BoolColumn get starred => boolean().withDefault(const Constant(false))();

  /// Relative to the app support directory, e.g. `audio/<id>.wav`. The
  /// absolute path changes on iOS updates and after a backup restore.
  TextColumn get audioPath => text().nullable()();
  IntColumn get audioBytes => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Lines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// OpenAI Realtime `item_id`. Events for a line arrive out of order, so
  /// every update is keyed on this.
  TextColumn get itemId => text()();

  /// Offset into the session's audio file; same clock as `audio_start_ms`.
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer().nullable()();
  TextColumn get originalText => text().nullable()();
  TextColumn get translatedText => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {sessionId, itemId},
      ];
}
