// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Untitled session'),
  );
  static const VerificationMeta _sourceLangMeta = const VerificationMeta(
    'sourceLang',
  );
  @override
  late final GeneratedColumn<String> sourceLang = GeneratedColumn<String>(
    'source_lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetLangMeta = const VerificationMeta(
    'targetLang',
  );
  @override
  late final GeneratedColumn<String> targetLang = GeneratedColumn<String>(
    'target_lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SessionStatus>($SessionsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<SessionMode, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SessionMode.captions.name),
      ).withConverter<SessionMode>($SessionsTable.$convertermode);
  static const VerificationMeta _starredMeta = const VerificationMeta(
    'starred',
  );
  @override
  late final GeneratedColumn<bool> starred = GeneratedColumn<bool>(
    'starred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("starred" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioBytesMeta = const VerificationMeta(
    'audioBytes',
  );
  @override
  late final GeneratedColumn<int> audioBytes = GeneratedColumn<int>(
    'audio_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _transcribeSecondsMeta = const VerificationMeta(
    'transcribeSeconds',
  );
  @override
  late final GeneratedColumn<double> transcribeSeconds =
      GeneratedColumn<double>(
        'transcribe_seconds',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _textInputTokensMeta = const VerificationMeta(
    'textInputTokens',
  );
  @override
  late final GeneratedColumn<int> textInputTokens = GeneratedColumn<int>(
    'text_input_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _textCachedTokensMeta = const VerificationMeta(
    'textCachedTokens',
  );
  @override
  late final GeneratedColumn<int> textCachedTokens = GeneratedColumn<int>(
    'text_cached_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _textOutputTokensMeta = const VerificationMeta(
    'textOutputTokens',
  );
  @override
  late final GeneratedColumn<int> textOutputTokens = GeneratedColumn<int>(
    'text_output_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _speechSecondsMeta = const VerificationMeta(
    'speechSeconds',
  );
  @override
  late final GeneratedColumn<double> speechSeconds = GeneratedColumn<double>(
    'speech_seconds',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    sourceLang,
    targetLang,
    createdAt,
    durationMs,
    status,
    mode,
    starred,
    audioPath,
    audioBytes,
    transcribeSeconds,
    textInputTokens,
    textCachedTokens,
    textOutputTokens,
    speechSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('source_lang')) {
      context.handle(
        _sourceLangMeta,
        sourceLang.isAcceptableOrUnknown(data['source_lang']!, _sourceLangMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceLangMeta);
    }
    if (data.containsKey('target_lang')) {
      context.handle(
        _targetLangMeta,
        targetLang.isAcceptableOrUnknown(data['target_lang']!, _targetLangMeta),
      );
    } else if (isInserting) {
      context.missing(_targetLangMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('starred')) {
      context.handle(
        _starredMeta,
        starred.isAcceptableOrUnknown(data['starred']!, _starredMeta),
      );
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    }
    if (data.containsKey('audio_bytes')) {
      context.handle(
        _audioBytesMeta,
        audioBytes.isAcceptableOrUnknown(data['audio_bytes']!, _audioBytesMeta),
      );
    }
    if (data.containsKey('transcribe_seconds')) {
      context.handle(
        _transcribeSecondsMeta,
        transcribeSeconds.isAcceptableOrUnknown(
          data['transcribe_seconds']!,
          _transcribeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('text_input_tokens')) {
      context.handle(
        _textInputTokensMeta,
        textInputTokens.isAcceptableOrUnknown(
          data['text_input_tokens']!,
          _textInputTokensMeta,
        ),
      );
    }
    if (data.containsKey('text_cached_tokens')) {
      context.handle(
        _textCachedTokensMeta,
        textCachedTokens.isAcceptableOrUnknown(
          data['text_cached_tokens']!,
          _textCachedTokensMeta,
        ),
      );
    }
    if (data.containsKey('text_output_tokens')) {
      context.handle(
        _textOutputTokensMeta,
        textOutputTokens.isAcceptableOrUnknown(
          data['text_output_tokens']!,
          _textOutputTokensMeta,
        ),
      );
    }
    if (data.containsKey('speech_seconds')) {
      context.handle(
        _speechSecondsMeta,
        speechSeconds.isAcceptableOrUnknown(
          data['speech_seconds']!,
          _speechSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sourceLang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_lang'],
      )!,
      targetLang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_lang'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      status: $SessionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      mode: $SessionsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        )!,
      ),
      starred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}starred'],
      )!,
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      ),
      audioBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}audio_bytes'],
      )!,
      transcribeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}transcribe_seconds'],
      ),
      textInputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}text_input_tokens'],
      )!,
      textCachedTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}text_cached_tokens'],
      )!,
      textOutputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}text_output_tokens'],
      )!,
      speechSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speech_seconds'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionStatus, String, String> $converterstatus =
      const EnumNameConverter<SessionStatus>(SessionStatus.values);
  static JsonTypeConverter2<SessionMode, String, String> $convertermode =
      const EnumNameConverter<SessionMode>(SessionMode.values);
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String title;
  final String sourceLang;
  final String targetLang;
  final DateTime createdAt;
  final int durationMs;
  final SessionStatus status;
  final SessionMode mode;
  final bool starred;

  /// Relative to the app support directory, e.g. `audio/<id>.wav`. The
  /// absolute path changes on iOS updates and after a backup restore.
  final String? audioPath;
  final int audioBytes;

  /// OpenAI usage for cost estimates. Null on sessions recorded before usage
  /// was tracked.
  final double? transcribeSeconds;
  final int textInputTokens;
  final int textCachedTokens;
  final int textOutputTokens;
  final double speechSeconds;
  const Session({
    required this.id,
    required this.title,
    required this.sourceLang,
    required this.targetLang,
    required this.createdAt,
    required this.durationMs,
    required this.status,
    required this.mode,
    required this.starred,
    this.audioPath,
    required this.audioBytes,
    this.transcribeSeconds,
    required this.textInputTokens,
    required this.textCachedTokens,
    required this.textOutputTokens,
    required this.speechSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['source_lang'] = Variable<String>(sourceLang);
    map['target_lang'] = Variable<String>(targetLang);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['duration_ms'] = Variable<int>(durationMs);
    {
      map['status'] = Variable<String>(
        $SessionsTable.$converterstatus.toSql(status),
      );
    }
    {
      map['mode'] = Variable<String>($SessionsTable.$convertermode.toSql(mode));
    }
    map['starred'] = Variable<bool>(starred);
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    map['audio_bytes'] = Variable<int>(audioBytes);
    if (!nullToAbsent || transcribeSeconds != null) {
      map['transcribe_seconds'] = Variable<double>(transcribeSeconds);
    }
    map['text_input_tokens'] = Variable<int>(textInputTokens);
    map['text_cached_tokens'] = Variable<int>(textCachedTokens);
    map['text_output_tokens'] = Variable<int>(textOutputTokens);
    map['speech_seconds'] = Variable<double>(speechSeconds);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      title: Value(title),
      sourceLang: Value(sourceLang),
      targetLang: Value(targetLang),
      createdAt: Value(createdAt),
      durationMs: Value(durationMs),
      status: Value(status),
      mode: Value(mode),
      starred: Value(starred),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      audioBytes: Value(audioBytes),
      transcribeSeconds: transcribeSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(transcribeSeconds),
      textInputTokens: Value(textInputTokens),
      textCachedTokens: Value(textCachedTokens),
      textOutputTokens: Value(textOutputTokens),
      speechSeconds: Value(speechSeconds),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      sourceLang: serializer.fromJson<String>(json['sourceLang']),
      targetLang: serializer.fromJson<String>(json['targetLang']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      status: $SessionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      mode: $SessionsTable.$convertermode.fromJson(
        serializer.fromJson<String>(json['mode']),
      ),
      starred: serializer.fromJson<bool>(json['starred']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      audioBytes: serializer.fromJson<int>(json['audioBytes']),
      transcribeSeconds: serializer.fromJson<double?>(
        json['transcribeSeconds'],
      ),
      textInputTokens: serializer.fromJson<int>(json['textInputTokens']),
      textCachedTokens: serializer.fromJson<int>(json['textCachedTokens']),
      textOutputTokens: serializer.fromJson<int>(json['textOutputTokens']),
      speechSeconds: serializer.fromJson<double>(json['speechSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'sourceLang': serializer.toJson<String>(sourceLang),
      'targetLang': serializer.toJson<String>(targetLang),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'durationMs': serializer.toJson<int>(durationMs),
      'status': serializer.toJson<String>(
        $SessionsTable.$converterstatus.toJson(status),
      ),
      'mode': serializer.toJson<String>(
        $SessionsTable.$convertermode.toJson(mode),
      ),
      'starred': serializer.toJson<bool>(starred),
      'audioPath': serializer.toJson<String?>(audioPath),
      'audioBytes': serializer.toJson<int>(audioBytes),
      'transcribeSeconds': serializer.toJson<double?>(transcribeSeconds),
      'textInputTokens': serializer.toJson<int>(textInputTokens),
      'textCachedTokens': serializer.toJson<int>(textCachedTokens),
      'textOutputTokens': serializer.toJson<int>(textOutputTokens),
      'speechSeconds': serializer.toJson<double>(speechSeconds),
    };
  }

  Session copyWith({
    String? id,
    String? title,
    String? sourceLang,
    String? targetLang,
    DateTime? createdAt,
    int? durationMs,
    SessionStatus? status,
    SessionMode? mode,
    bool? starred,
    Value<String?> audioPath = const Value.absent(),
    int? audioBytes,
    Value<double?> transcribeSeconds = const Value.absent(),
    int? textInputTokens,
    int? textCachedTokens,
    int? textOutputTokens,
    double? speechSeconds,
  }) => Session(
    id: id ?? this.id,
    title: title ?? this.title,
    sourceLang: sourceLang ?? this.sourceLang,
    targetLang: targetLang ?? this.targetLang,
    createdAt: createdAt ?? this.createdAt,
    durationMs: durationMs ?? this.durationMs,
    status: status ?? this.status,
    mode: mode ?? this.mode,
    starred: starred ?? this.starred,
    audioPath: audioPath.present ? audioPath.value : this.audioPath,
    audioBytes: audioBytes ?? this.audioBytes,
    transcribeSeconds: transcribeSeconds.present
        ? transcribeSeconds.value
        : this.transcribeSeconds,
    textInputTokens: textInputTokens ?? this.textInputTokens,
    textCachedTokens: textCachedTokens ?? this.textCachedTokens,
    textOutputTokens: textOutputTokens ?? this.textOutputTokens,
    speechSeconds: speechSeconds ?? this.speechSeconds,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      sourceLang: data.sourceLang.present
          ? data.sourceLang.value
          : this.sourceLang,
      targetLang: data.targetLang.present
          ? data.targetLang.value
          : this.targetLang,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      status: data.status.present ? data.status.value : this.status,
      mode: data.mode.present ? data.mode.value : this.mode,
      starred: data.starred.present ? data.starred.value : this.starred,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      audioBytes: data.audioBytes.present
          ? data.audioBytes.value
          : this.audioBytes,
      transcribeSeconds: data.transcribeSeconds.present
          ? data.transcribeSeconds.value
          : this.transcribeSeconds,
      textInputTokens: data.textInputTokens.present
          ? data.textInputTokens.value
          : this.textInputTokens,
      textCachedTokens: data.textCachedTokens.present
          ? data.textCachedTokens.value
          : this.textCachedTokens,
      textOutputTokens: data.textOutputTokens.present
          ? data.textOutputTokens.value
          : this.textOutputTokens,
      speechSeconds: data.speechSeconds.present
          ? data.speechSeconds.value
          : this.speechSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sourceLang: $sourceLang, ')
          ..write('targetLang: $targetLang, ')
          ..write('createdAt: $createdAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('status: $status, ')
          ..write('mode: $mode, ')
          ..write('starred: $starred, ')
          ..write('audioPath: $audioPath, ')
          ..write('audioBytes: $audioBytes, ')
          ..write('transcribeSeconds: $transcribeSeconds, ')
          ..write('textInputTokens: $textInputTokens, ')
          ..write('textCachedTokens: $textCachedTokens, ')
          ..write('textOutputTokens: $textOutputTokens, ')
          ..write('speechSeconds: $speechSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    sourceLang,
    targetLang,
    createdAt,
    durationMs,
    status,
    mode,
    starred,
    audioPath,
    audioBytes,
    transcribeSeconds,
    textInputTokens,
    textCachedTokens,
    textOutputTokens,
    speechSeconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.title == this.title &&
          other.sourceLang == this.sourceLang &&
          other.targetLang == this.targetLang &&
          other.createdAt == this.createdAt &&
          other.durationMs == this.durationMs &&
          other.status == this.status &&
          other.mode == this.mode &&
          other.starred == this.starred &&
          other.audioPath == this.audioPath &&
          other.audioBytes == this.audioBytes &&
          other.transcribeSeconds == this.transcribeSeconds &&
          other.textInputTokens == this.textInputTokens &&
          other.textCachedTokens == this.textCachedTokens &&
          other.textOutputTokens == this.textOutputTokens &&
          other.speechSeconds == this.speechSeconds);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> sourceLang;
  final Value<String> targetLang;
  final Value<DateTime> createdAt;
  final Value<int> durationMs;
  final Value<SessionStatus> status;
  final Value<SessionMode> mode;
  final Value<bool> starred;
  final Value<String?> audioPath;
  final Value<int> audioBytes;
  final Value<double?> transcribeSeconds;
  final Value<int> textInputTokens;
  final Value<int> textCachedTokens;
  final Value<int> textOutputTokens;
  final Value<double> speechSeconds;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.sourceLang = const Value.absent(),
    this.targetLang = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.status = const Value.absent(),
    this.mode = const Value.absent(),
    this.starred = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.audioBytes = const Value.absent(),
    this.transcribeSeconds = const Value.absent(),
    this.textInputTokens = const Value.absent(),
    this.textCachedTokens = const Value.absent(),
    this.textOutputTokens = const Value.absent(),
    this.speechSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    required String sourceLang,
    required String targetLang,
    required DateTime createdAt,
    this.durationMs = const Value.absent(),
    required SessionStatus status,
    this.mode = const Value.absent(),
    this.starred = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.audioBytes = const Value.absent(),
    this.transcribeSeconds = const Value.absent(),
    this.textInputTokens = const Value.absent(),
    this.textCachedTokens = const Value.absent(),
    this.textOutputTokens = const Value.absent(),
    this.speechSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceLang = Value(sourceLang),
       targetLang = Value(targetLang),
       createdAt = Value(createdAt),
       status = Value(status);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? sourceLang,
    Expression<String>? targetLang,
    Expression<DateTime>? createdAt,
    Expression<int>? durationMs,
    Expression<String>? status,
    Expression<String>? mode,
    Expression<bool>? starred,
    Expression<String>? audioPath,
    Expression<int>? audioBytes,
    Expression<double>? transcribeSeconds,
    Expression<int>? textInputTokens,
    Expression<int>? textCachedTokens,
    Expression<int>? textOutputTokens,
    Expression<double>? speechSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (sourceLang != null) 'source_lang': sourceLang,
      if (targetLang != null) 'target_lang': targetLang,
      if (createdAt != null) 'created_at': createdAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (status != null) 'status': status,
      if (mode != null) 'mode': mode,
      if (starred != null) 'starred': starred,
      if (audioPath != null) 'audio_path': audioPath,
      if (audioBytes != null) 'audio_bytes': audioBytes,
      if (transcribeSeconds != null) 'transcribe_seconds': transcribeSeconds,
      if (textInputTokens != null) 'text_input_tokens': textInputTokens,
      if (textCachedTokens != null) 'text_cached_tokens': textCachedTokens,
      if (textOutputTokens != null) 'text_output_tokens': textOutputTokens,
      if (speechSeconds != null) 'speech_seconds': speechSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? sourceLang,
    Value<String>? targetLang,
    Value<DateTime>? createdAt,
    Value<int>? durationMs,
    Value<SessionStatus>? status,
    Value<SessionMode>? mode,
    Value<bool>? starred,
    Value<String?>? audioPath,
    Value<int>? audioBytes,
    Value<double?>? transcribeSeconds,
    Value<int>? textInputTokens,
    Value<int>? textCachedTokens,
    Value<int>? textOutputTokens,
    Value<double>? speechSeconds,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      createdAt: createdAt ?? this.createdAt,
      durationMs: durationMs ?? this.durationMs,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      starred: starred ?? this.starred,
      audioPath: audioPath ?? this.audioPath,
      audioBytes: audioBytes ?? this.audioBytes,
      transcribeSeconds: transcribeSeconds ?? this.transcribeSeconds,
      textInputTokens: textInputTokens ?? this.textInputTokens,
      textCachedTokens: textCachedTokens ?? this.textCachedTokens,
      textOutputTokens: textOutputTokens ?? this.textOutputTokens,
      speechSeconds: speechSeconds ?? this.speechSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sourceLang.present) {
      map['source_lang'] = Variable<String>(sourceLang.value);
    }
    if (targetLang.present) {
      map['target_lang'] = Variable<String>(targetLang.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SessionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
        $SessionsTable.$convertermode.toSql(mode.value),
      );
    }
    if (starred.present) {
      map['starred'] = Variable<bool>(starred.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (audioBytes.present) {
      map['audio_bytes'] = Variable<int>(audioBytes.value);
    }
    if (transcribeSeconds.present) {
      map['transcribe_seconds'] = Variable<double>(transcribeSeconds.value);
    }
    if (textInputTokens.present) {
      map['text_input_tokens'] = Variable<int>(textInputTokens.value);
    }
    if (textCachedTokens.present) {
      map['text_cached_tokens'] = Variable<int>(textCachedTokens.value);
    }
    if (textOutputTokens.present) {
      map['text_output_tokens'] = Variable<int>(textOutputTokens.value);
    }
    if (speechSeconds.present) {
      map['speech_seconds'] = Variable<double>(speechSeconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sourceLang: $sourceLang, ')
          ..write('targetLang: $targetLang, ')
          ..write('createdAt: $createdAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('status: $status, ')
          ..write('mode: $mode, ')
          ..write('starred: $starred, ')
          ..write('audioPath: $audioPath, ')
          ..write('audioBytes: $audioBytes, ')
          ..write('transcribeSeconds: $transcribeSeconds, ')
          ..write('textInputTokens: $textInputTokens, ')
          ..write('textCachedTokens: $textCachedTokens, ')
          ..write('textOutputTokens: $textOutputTokens, ')
          ..write('speechSeconds: $speechSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LinesTable extends Lines with TableInfo<$LinesTable, Line> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalTextMeta = const VerificationMeta(
    'originalText',
  );
  @override
  late final GeneratedColumn<String> originalText = GeneratedColumn<String>(
    'original_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _translatedTextMeta = const VerificationMeta(
    'translatedText',
  );
  @override
  late final GeneratedColumn<String> translatedText = GeneratedColumn<String>(
    'translated_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    itemId,
    startMs,
    endMs,
    originalText,
    translatedText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<Line> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    }
    if (data.containsKey('original_text')) {
      context.handle(
        _originalTextMeta,
        originalText.isAcceptableOrUnknown(
          data['original_text']!,
          _originalTextMeta,
        ),
      );
    }
    if (data.containsKey('translated_text')) {
      context.handle(
        _translatedTextMeta,
        translatedText.isAcceptableOrUnknown(
          data['translated_text']!,
          _translatedTextMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, itemId},
  ];
  @override
  Line map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Line(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      ),
      originalText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_text'],
      ),
      translatedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translated_text'],
      ),
    );
  }

  @override
  $LinesTable createAlias(String alias) {
    return $LinesTable(attachedDatabase, alias);
  }
}

class Line extends DataClass implements Insertable<Line> {
  final int id;
  final String sessionId;

  /// Segment key assigned when speech starts, before OpenAI has an item id.
  /// Events for a line arrive out of order, so every update is keyed on this.
  final String itemId;

  /// Offset into the session's audio file; same clock as `audio_start_ms`.
  final int startMs;
  final int? endMs;
  final String? originalText;
  final String? translatedText;
  const Line({
    required this.id,
    required this.sessionId,
    required this.itemId,
    required this.startMs,
    this.endMs,
    this.originalText,
    this.translatedText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['item_id'] = Variable<String>(itemId);
    map['start_ms'] = Variable<int>(startMs);
    if (!nullToAbsent || endMs != null) {
      map['end_ms'] = Variable<int>(endMs);
    }
    if (!nullToAbsent || originalText != null) {
      map['original_text'] = Variable<String>(originalText);
    }
    if (!nullToAbsent || translatedText != null) {
      map['translated_text'] = Variable<String>(translatedText);
    }
    return map;
  }

  LinesCompanion toCompanion(bool nullToAbsent) {
    return LinesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      itemId: Value(itemId),
      startMs: Value(startMs),
      endMs: endMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endMs),
      originalText: originalText == null && nullToAbsent
          ? const Value.absent()
          : Value(originalText),
      translatedText: translatedText == null && nullToAbsent
          ? const Value.absent()
          : Value(translatedText),
    );
  }

  factory Line.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Line(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int?>(json['endMs']),
      originalText: serializer.fromJson<String?>(json['originalText']),
      translatedText: serializer.fromJson<String?>(json['translatedText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'itemId': serializer.toJson<String>(itemId),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int?>(endMs),
      'originalText': serializer.toJson<String?>(originalText),
      'translatedText': serializer.toJson<String?>(translatedText),
    };
  }

  Line copyWith({
    int? id,
    String? sessionId,
    String? itemId,
    int? startMs,
    Value<int?> endMs = const Value.absent(),
    Value<String?> originalText = const Value.absent(),
    Value<String?> translatedText = const Value.absent(),
  }) => Line(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    itemId: itemId ?? this.itemId,
    startMs: startMs ?? this.startMs,
    endMs: endMs.present ? endMs.value : this.endMs,
    originalText: originalText.present ? originalText.value : this.originalText,
    translatedText: translatedText.present
        ? translatedText.value
        : this.translatedText,
  );
  Line copyWithCompanion(LinesCompanion data) {
    return Line(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      originalText: data.originalText.present
          ? data.originalText.value
          : this.originalText,
      translatedText: data.translatedText.present
          ? data.translatedText.value
          : this.translatedText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Line(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('itemId: $itemId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('originalText: $originalText, ')
          ..write('translatedText: $translatedText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    itemId,
    startMs,
    endMs,
    originalText,
    translatedText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Line &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.itemId == this.itemId &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.originalText == this.originalText &&
          other.translatedText == this.translatedText);
}

class LinesCompanion extends UpdateCompanion<Line> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<String> itemId;
  final Value<int> startMs;
  final Value<int?> endMs;
  final Value<String?> originalText;
  final Value<String?> translatedText;
  const LinesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.originalText = const Value.absent(),
    this.translatedText = const Value.absent(),
  });
  LinesCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required String itemId,
    required int startMs,
    this.endMs = const Value.absent(),
    this.originalText = const Value.absent(),
    this.translatedText = const Value.absent(),
  }) : sessionId = Value(sessionId),
       itemId = Value(itemId),
       startMs = Value(startMs);
  static Insertable<Line> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<String>? itemId,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<String>? originalText,
    Expression<String>? translatedText,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (itemId != null) 'item_id': itemId,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (originalText != null) 'original_text': originalText,
      if (translatedText != null) 'translated_text': translatedText,
    });
  }

  LinesCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<String>? itemId,
    Value<int>? startMs,
    Value<int?>? endMs,
    Value<String?>? originalText,
    Value<String?>? translatedText,
  }) {
    return LinesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      itemId: itemId ?? this.itemId,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (originalText.present) {
      map['original_text'] = Variable<String>(originalText.value);
    }
    if (translatedText.present) {
      map['translated_text'] = Variable<String>(translatedText.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LinesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('itemId: $itemId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('originalText: $originalText, ')
          ..write('translatedText: $translatedText')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $LinesTable lines = $LinesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sessions, lines];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lines', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  Value<String> title,
  required String sourceLang,
  required String targetLang,
  required DateTime createdAt,
  Value<int> durationMs,
  required SessionStatus status,
  Value<SessionMode> mode,
  Value<bool> starred,
  Value<String?> audioPath,
  Value<int> audioBytes,
  Value<double?> transcribeSeconds,
  Value<int> textInputTokens,
  Value<int> textCachedTokens,
  Value<int> textOutputTokens,
  Value<double> speechSeconds,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> sourceLang,
  Value<String> targetLang,
  Value<DateTime> createdAt,
  Value<int> durationMs,
  Value<SessionStatus> status,
  Value<SessionMode> mode,
  Value<bool> starred,
  Value<String?> audioPath,
  Value<int> audioBytes,
  Value<double?> transcribeSeconds,
  Value<int> textInputTokens,
  Value<int> textCachedTokens,
  Value<int> textOutputTokens,
  Value<double> speechSeconds,
  Value<int> rowid,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LinesTable, List<Line>> _linesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.lines,
    aliasName: 'sessions__id__lines__session_id',
  );

  $$LinesTableProcessedTableManager get linesRefs {
    final manager = $$LinesTableTableManager(
      $_db,
      $_db.lines,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_linesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLang => $composableBuilder(
    column: $table.sourceLang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetLang => $composableBuilder(
    column: $table.targetLang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionStatus, SessionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionMode, SessionMode, String> get mode =>
      $composableBuilder(
        column: $table.mode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get starred => $composableBuilder(
    column: $table.starred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get audioBytes => $composableBuilder(
    column: $table.audioBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get transcribeSeconds => $composableBuilder(
    column: $table.transcribeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get textInputTokens => $composableBuilder(
    column: $table.textInputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get textCachedTokens => $composableBuilder(
    column: $table.textCachedTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get textOutputTokens => $composableBuilder(
    column: $table.textOutputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speechSeconds => $composableBuilder(
    column: $table.speechSeconds,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> linesRefs(
    Expression<bool> Function($$LinesTableFilterComposer f) f,
  ) {
    final $$LinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lines,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinesTableFilterComposer(
            $db: $db,
            $table: $db.lines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLang => $composableBuilder(
    column: $table.sourceLang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetLang => $composableBuilder(
    column: $table.targetLang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get starred => $composableBuilder(
    column: $table.starred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get audioBytes => $composableBuilder(
    column: $table.audioBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get transcribeSeconds => $composableBuilder(
    column: $table.transcribeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get textInputTokens => $composableBuilder(
    column: $table.textInputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get textCachedTokens => $composableBuilder(
    column: $table.textCachedTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get textOutputTokens => $composableBuilder(
    column: $table.textOutputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speechSeconds => $composableBuilder(
    column: $table.speechSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get sourceLang => $composableBuilder(
    column: $table.sourceLang,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetLang => $composableBuilder(
    column: $table.targetLang,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SessionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<bool> get starred =>
      $composableBuilder(column: $table.starred, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<int> get audioBytes => $composableBuilder(
    column: $table.audioBytes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get transcribeSeconds => $composableBuilder(
    column: $table.transcribeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get textInputTokens => $composableBuilder(
    column: $table.textInputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get textCachedTokens => $composableBuilder(
    column: $table.textCachedTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get textOutputTokens => $composableBuilder(
    column: $table.textOutputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speechSeconds => $composableBuilder(
    column: $table.speechSeconds,
    builder: (column) => column,
  );

  Expression<T> linesRefs<T extends Object>(
    Expression<T> Function($$LinesTableAnnotationComposer a) f,
  ) {
    final $$LinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lines,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinesTableAnnotationComposer(
            $db: $db,
            $table: $db.lines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({bool linesRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> sourceLang = const Value.absent(),
                Value<String> targetLang = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<SessionStatus> status = const Value.absent(),
                Value<SessionMode> mode = const Value.absent(),
                Value<bool> starred = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<int> audioBytes = const Value.absent(),
                Value<double?> transcribeSeconds = const Value.absent(),
                Value<int> textInputTokens = const Value.absent(),
                Value<int> textCachedTokens = const Value.absent(),
                Value<int> textOutputTokens = const Value.absent(),
                Value<double> speechSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                title: title,
                sourceLang: sourceLang,
                targetLang: targetLang,
                createdAt: createdAt,
                durationMs: durationMs,
                status: status,
                mode: mode,
                starred: starred,
                audioPath: audioPath,
                audioBytes: audioBytes,
                transcribeSeconds: transcribeSeconds,
                textInputTokens: textInputTokens,
                textCachedTokens: textCachedTokens,
                textOutputTokens: textOutputTokens,
                speechSeconds: speechSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> title = const Value.absent(),
                required String sourceLang,
                required String targetLang,
                required DateTime createdAt,
                Value<int> durationMs = const Value.absent(),
                required SessionStatus status,
                Value<SessionMode> mode = const Value.absent(),
                Value<bool> starred = const Value.absent(),
                Value<String?> audioPath = const Value.absent(),
                Value<int> audioBytes = const Value.absent(),
                Value<double?> transcribeSeconds = const Value.absent(),
                Value<int> textInputTokens = const Value.absent(),
                Value<int> textCachedTokens = const Value.absent(),
                Value<int> textOutputTokens = const Value.absent(),
                Value<double> speechSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                title: title,
                sourceLang: sourceLang,
                targetLang: targetLang,
                createdAt: createdAt,
                durationMs: durationMs,
                status: status,
                mode: mode,
                starred: starred,
                audioPath: audioPath,
                audioBytes: audioBytes,
                transcribeSeconds: transcribeSeconds,
                textInputTokens: textInputTokens,
                textCachedTokens: textCachedTokens,
                textOutputTokens: textOutputTokens,
                speechSeconds: speechSeconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, Session>(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({linesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (linesRefs) db.lines],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (linesRefs)
                    await $_getPrefetchedDataByColumns<
                      Session,
                      $SessionsTable,
                      Line,
                      $LinesTable
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._linesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SessionsTableReferences(db, table, p0).linesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'session_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({bool linesRefs})
    >;
typedef $$LinesTableCreateCompanionBuilder = LinesCompanion Function({
  Value<int> id,
  required String sessionId,
  required String itemId,
  required int startMs,
  Value<int?> endMs,
  Value<String?> originalText,
  Value<String?> translatedText,
});
typedef $$LinesTableUpdateCompanionBuilder = LinesCompanion Function({
  Value<int> id,
  Value<String> sessionId,
  Value<String> itemId,
  Value<int> startMs,
  Value<int?> endMs,
  Value<String?> originalText,
  Value<String?> translatedText,
});

final class $$LinesTableReferences
    extends BaseReferences<_$AppDatabase, $LinesTable, Line> {
  $$LinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('lines__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LinesTableFilterComposer extends Composer<_$AppDatabase, $LinesTable> {
  $$LinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translatedText => $composableBuilder(
    column: $table.translatedText,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LinesTableOrderingComposer
    extends Composer<_$AppDatabase, $LinesTable> {
  $$LinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translatedText => $composableBuilder(
    column: $table.translatedText,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LinesTable> {
  $$LinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  GeneratedColumn<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get translatedText => $composableBuilder(
    column: $table.translatedText,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LinesTable,
          Line,
          $$LinesTableFilterComposer,
          $$LinesTableOrderingComposer,
          $$LinesTableAnnotationComposer,
          $$LinesTableCreateCompanionBuilder,
          $$LinesTableUpdateCompanionBuilder,
          (Line, $$LinesTableReferences),
          Line,
          PrefetchHooks Function({bool sessionId})
        > {
  $$LinesTableTableManager(_$AppDatabase db, $LinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int?> endMs = const Value.absent(),
                Value<String?> originalText = const Value.absent(),
                Value<String?> translatedText = const Value.absent(),
              }) => LinesCompanion(
                id: id,
                sessionId: sessionId,
                itemId: itemId,
                startMs: startMs,
                endMs: endMs,
                originalText: originalText,
                translatedText: translatedText,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required String itemId,
                required int startMs,
                Value<int?> endMs = const Value.absent(),
                Value<String?> originalText = const Value.absent(),
                Value<String?> translatedText = const Value.absent(),
              }) => LinesCompanion.insert(
                id: id,
                sessionId: sessionId,
                itemId: itemId,
                startMs: startMs,
                endMs: endMs,
                originalText: originalText,
                translatedText: translatedText,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LinesTable, Line>(table),
                  $$LinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$LinesTableReferences._sessionIdTable(
                          db,
                        ),
                        referencedColumn: $$LinesTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LinesTable,
      Line,
      $$LinesTableFilterComposer,
      $$LinesTableOrderingComposer,
      $$LinesTableAnnotationComposer,
      $$LinesTableCreateCompanionBuilder,
      $$LinesTableUpdateCompanionBuilder,
      (Line, $$LinesTableReferences),
      Line,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$LinesTableTableManager get lines =>
      $$LinesTableTableManager(_db, _db.lines);
}
