import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../audio/audio_file_sink.dart';
import '../audio/vad.dart';
import '../audio/wav_writer.dart';
import '../core/languages.dart';
import '../data/db/app_database.dart';
import '../data/providers.dart';
import '../openai/openai_error.dart';
import '../openai/text_client.dart';
import '../openai/transcription_client.dart';
import 'background_recording.dart';
import 'interpreter_engine.dart';
import 'session_storage.dart';
import 'translation_speaker.dart';

enum LivePhase { idle, connecting, live, stopping }

@immutable
class LiveState {
  const LiveState({
    this.phase = LivePhase.idle,
    this.sessionId,
    this.elapsedMs = 0,
    this.level = 0,
    this.speaking = false,
    this.reconnecting = false,
    this.partials = const {},
    this.error,
    this.savedSessionId,
    this.savedWithAudio = false,
  });

  final LivePhase phase;
  final String? sessionId;
  final int elapsedMs;
  final double level;
  final bool speaking;

  /// The connection to OpenAI dropped. Recording continues and buffered
  /// sentences are sent once it's back.
  final bool reconnecting;

  /// In-progress transcript text by segment key, before the final arrives.
  final Map<String, String> partials;
  final String? error;

  /// Set after Stop when a session was saved, so the UI can offer to open it.
  final String? savedSessionId;
  final bool savedWithAudio;

  bool get active => phase != LivePhase.idle;

  LiveState copyWith({
    int? elapsedMs,
    double? level,
    bool? speaking,
    bool? reconnecting,
    Map<String, String>? partials,
    String? error,
    bool clearError = false,
    LivePhase? phase,
  }) {
    return LiveState(
      phase: phase ?? this.phase,
      sessionId: sessionId,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      level: level ?? this.level,
      speaking: speaking ?? this.speaking,
      reconnecting: reconnecting ?? this.reconnecting,
      partials: partials ?? this.partials,
      error: clearError ? null : error ?? this.error,
      savedSessionId: savedSessionId,
      savedWithAudio: savedWithAudio,
    );
  }
}

final liveSessionProvider =
    NotifierProvider<LiveSessionController, LiveState>(LiveSessionController.new);

class LiveSessionController extends Notifier<LiveState> {
  static const _minVoicedMs = 250;
  static const _contextLines = 3;
  static const _resendChunkBytes = 48000;
  static const _reconnectDelays = [1, 2, 4, 8, 15, 30];
  static const _uiInterval = Duration(milliseconds: 66);

  AppDatabase get _db => ref.read(databaseProvider);

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<TranscriptionEvent>? _eventSub;
  TranscriptionClient? _client;
  OpenAiTextClient? _text;
  Translator? _translator;
  TranslationSpeaker? _speaker;
  InterpreterEngine? _interpreter;
  SessionMode _mode = SessionMode.captions;
  AudioFileSink? _sink;
  Vad? _vad;

  String? _sessionId;
  String _apiKey = '';
  String _sourceCode = '';
  String _from = '';
  String _to = '';
  int _bytes = 0;
  int _segCounter = 0;
  String? _currentSeg;
  DateTime _lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  /// Bumped on teardown so a reconnect loop from an old session gives up.
  int _generation = 0;

  /// Segments committed to OpenAI, oldest first, waiting for their item id.
  final _awaitingItemId = Queue<String>();
  final _itemToSeg = <String, String>{};

  /// Audio of each segment until its transcript arrives, so it can be sent
  /// again after a reconnect.
  final _segAudio = <String, BytesBuilder>{};

  /// Ended segments that still need sending on the next connection.
  final _needsResend = <String>[];

  /// Segments with no final transcript or translation yet.
  final _unresolved = <String>{};
  final _recent = <(String, String)>[];

  @override
  LiveState build() {
    ref.onDispose(_teardown);
    return const LiveState();
  }

  void clearMessage() {
    if (state.active) {
      state = state.copyWith(clearError: true);
    } else if (state.error != null || state.savedSessionId != null) {
      state = const LiveState();
    }
  }

  Future<void> start() async {
    if (state.active) return;
    final key = await ref.read(apiKeyProvider.future);
    if (key == null || key.isEmpty) {
      state = const LiveState(error: 'Add your OpenAI API key in Settings first.');
      return;
    }
    final settings = ref.read(settingsProvider);
    _apiKey = key;
    _sourceCode = settings.sourceLang;
    _from = languageFor(settings.sourceLang).name;
    _to = languageFor(settings.targetLang).name;
    state = const LiveState(phase: LivePhase.connecting);

    try {
      final recorder = _recorder = AudioRecorder();
      if (!await recorder.hasPermission()) {
        throw OpenAiException(_micPermissionHelp());
      }

      _mode = settings.mode;
      final captions = _mode == SessionMode.captions;
      if (captions) {
        _attach(await TranscriptionClient.connect(apiKey: key, language: _sourceCode));
      }
      final id = _sessionId = const Uuid().v4();
      final db = _db;
      _text = OpenAiTextClient(
        key,
        onUsage: (u) => db.addUsage(id, textInput: u.input, textCached: u.cached, textOutput: u.output),
      );
      _translator = Translator(_text!);
      if (captions && settings.speakTranslation) {
        _speaker = TranslationSpeaker(
          _text!,
          onSpoken: (d) => db.addUsage(id, speechSeconds: d.inMilliseconds / 1000),
        );
      }
      _sink = settings.saveAudio ? await openAudioFileSink(id) : null;
      await _db.createSession(
        id: id,
        sourceLang: settings.sourceLang,
        targetLang: settings.targetLang,
        mode: _mode,
        audioPath: _sink?.relativePath,
      );
      if (!captions) {
        final interpreter = _interpreter = InterpreterEngine(
          db: _db,
          sessionId: id,
          apiKey: key,
          targetLanguage: settings.targetLang,
          onReconnecting: (r) => state = state.copyWith(reconnecting: r),
          onError: (m) => state = state.copyWith(error: m),
          onFatal: _fail,
        );
        await interpreter.connect();
      }

      _vad = Vad();
      _bytes = 0;
      _segCounter = 0;

      // Other apps must keep playing at full volume: the default interruption
      // mode takes Android audio focus (pausing YouTube etc.), and echoCancel
      // on macOS/iOS switches to the voice-processing unit, which ducks all
      // other audio while recording.
      final mic = await recorder.startStream(RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: WavWriter.sampleRate,
        numChannels: 1,
        echoCancel: defaultTargetPlatform != TargetPlatform.macOS &&
            defaultTargetPlatform != TargetPlatform.iOS,
        noiseSuppress: true,
        audioInterruption: AudioInterruptionMode.none,
        iosConfig: const IosRecordConfig(categoryOptions: [
          IosAudioCategoryOption.mixWithOthers,
          IosAudioCategoryOption.defaultToSpeaker,
          IosAudioCategoryOption.allowBluetooth,
          IosAudioCategoryOption.allowBluetoothA2DP,
        ]),
      ));
      _micSub = mic.listen(
        _onAudio,
        onError: (Object e) => _fail('Microphone stopped: $e'),
      );
      state = LiveState(phase: LivePhase.live, sessionId: id);
      unawaited(BackgroundRecording.start(onStopPressed: () => stop()));
    } catch (e) {
      final sessionId = _sessionId;
      await _teardown();
      if (sessionId != null) await _discardIfEmpty(sessionId);
      state = LiveState(error: _describe(e));
    }
  }

  /// [reason] is shown afterwards when the session ended because of an error.
  Future<void> stop({String? reason}) async {
    if (state.phase != LivePhase.live) return;
    final id = _sessionId!;
    state = state.copyWith(phase: LivePhase.stopping);

    await _micSub?.cancel();
    _micSub = null;
    await _recorder?.stop();
    for (final e in _vad?.flush() ?? const <VadEvent>[]) {
      _handleVad(e);
    }
    final interpreter = _interpreter;
    if (interpreter != null) await interpreter.finish();

    // Give in-flight transcripts and translations a moment to land. A
    // reconnect still in progress keeps going during this wait.
    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (_unresolved.isNotEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final untranscribed = _needsResend.length + _awaitingItemId.length;

    final sink = _sink;
    _sink = null;
    await sink?.close();
    final translator = _translator;
    await _teardown(keepText: true);

    if (interpreter != null) {
      // Speech the model produced no text for leaves empty lines behind.
      for (final l in await _db.linesFor(id)) {
        if (l.originalText == null && l.translatedText == null) {
          await _db.deleteLine(id, l.itemId);
        }
      }
    }
    final lines = await _db.linesFor(id);
    if (lines.isEmpty) {
      await _discardIfEmpty(id);
      _text?.close();
      _text = null;
      state = LiveState(error: reason ?? 'Nothing was heard, so the session was not saved.');
      return;
    }

    await _db.updateSession(
      id,
      SessionsCompanion(
        status: const Value(SessionStatus.complete),
        durationMs: Value(_bytes ~/ WavWriter.bytesPerMs),
        audioBytes: Value(sink?.fileBytes ?? 0),
      ),
    );
    final note = untranscribed > 0
        ? '$untranscribed ${untranscribed == 1 ? 'sentence was' : 'sentences were'} not transcribed because the connection was lost.'
        : null;
    state = LiveState(savedSessionId: id, savedWithAudio: sink != null, error: reason ?? note);
    unawaited(_nameSession(id, lines, translator));
  }

  void _attach(TranscriptionClient client) {
    _client = client;
    _eventSub = client.events.listen(_onEvent);
  }

  void _onAudio(Uint8List chunk) {
    final pcm = Uint8List.fromList(chunk);
    _sink?.append(pcm);
    _bytes += pcm.length;
    final vad = _vad!;
    // While the app speaks a translation, the mic would pick it up and
    // transcribe it. The file still gets the real audio.
    final suppress = (_speaker?.suppressMic ?? false) || (_interpreter?.suppressMic ?? false);
    final heard = suppress ? Uint8List(pcm.length) : pcm;
    _interpreter?.addAudio(heard);
    for (final e in vad.process(heard)) {
      _handleVad(e);
    }
    // The mic delivers chunks far faster than the eye needs; redrawing the
    // Live screen for each one costs battery for no visible gain.
    final now = DateTime.now();
    if (vad.inSpeech == state.speaking && now.difference(_lastUiUpdate) < _uiInterval) return;
    _lastUiUpdate = now;
    state = state.copyWith(
      elapsedMs: _bytes ~/ WavWriter.bytesPerMs,
      level: vad.level,
      speaking: vad.inSpeech,
    );
  }

  void _handleVad(VadEvent e) {
    final id = _sessionId;
    if (id == null) return;
    final interpreter = _interpreter;
    if (interpreter != null) {
      _handleVadInterpreter(interpreter, e);
      return;
    }
    switch (e) {
      case VadSpeechStart(:final startMs, :final preRoll):
        final seg = 'seg_${_segCounter++}';
        _currentSeg = seg;
        _segAudio[seg] = BytesBuilder(copy: false);
        _db.createLine(id, seg, startMs);
        _sendAudio(seg, preRoll);
      case VadAudio(:final bytes):
        final seg = _currentSeg;
        if (seg != null) _sendAudio(seg, bytes);
      case VadSpeechEnd(:final endMs, :final voicedMs):
        final seg = _currentSeg;
        _currentSeg = null;
        if (seg == null) return;
        if (voicedMs < _minVoicedMs) {
          _client?.clear();
          _segAudio.remove(seg);
          _db.deleteLine(id, seg);
          return;
        }
        _unresolved.add(seg);
        _db.updateLine(id, seg, LinesCompanion(endMs: Value(endMs)));
        final client = _client;
        if (client == null) {
          _needsResend.add(seg);
        } else {
          client.commit();
          if (!_itemToSeg.containsValue(seg)) _awaitingItemId.add(seg);
        }
    }
  }

  void _handleVadInterpreter(InterpreterEngine interpreter, VadEvent e) {
    switch (e) {
      case VadSpeechStart(:final startMs):
        final seg = 'seg_${_segCounter++}';
        _currentSeg = seg;
        interpreter.lineStarted(seg, startMs);
      case VadAudio():
        break;
      case VadSpeechEnd(:final endMs, :final voicedMs):
        final seg = _currentSeg;
        _currentSeg = null;
        if (seg == null) return;
        voicedMs < _minVoicedMs ? interpreter.lineDiscarded(seg) : interpreter.lineEnded(seg, endMs);
    }
  }

  void _sendAudio(String seg, Uint8List bytes) {
    if (bytes.isEmpty) return;
    _segAudio[seg]?.add(bytes);
    _client?.appendAudio(bytes);
  }

  void _onEvent(TranscriptionEvent e) {
    final id = _sessionId;
    if (id == null) return;
    switch (e) {
      case TranscriptCommitted(:final itemId):
        if (!_itemToSeg.containsKey(itemId) && _awaitingItemId.isNotEmpty) {
          _itemToSeg[itemId] = _awaitingItemId.removeFirst();
        }
      case TranscriptDelta(:final itemId, :final delta):
        final seg = _segFor(itemId);
        if (seg == null) return;
        final partials = {...state.partials};
        partials[seg] = (partials[seg] ?? '') + delta;
        state = state.copyWith(partials: partials);
      case TranscriptCompleted(:final itemId, :final transcript, :final billedSeconds):
        if (billedSeconds > 0) _db.addUsage(id, transcribeSeconds: billedSeconds);
        final seg = _segFor(itemId);
        if (seg == null) return;
        _itemToSeg.remove(itemId);
        _segAudio.remove(seg);
        _removePartial(seg);
        final text = transcript.trim();
        if (text.isEmpty) {
          _db.deleteLine(id, seg);
          _unresolved.remove(seg);
          return;
        }
        _db.updateLine(id, seg, LinesCompanion(originalText: Value(text)));
        _translate(id, seg, text);
      case TranscriptFailed(:final itemId):
        final seg = _segFor(itemId);
        if (seg == null) return;
        _itemToSeg.remove(itemId);
        _segAudio.remove(seg);
        _removePartial(seg);
        _db.deleteLine(id, seg);
        _unresolved.remove(seg);
      case TranscriptError(:final error):
        if (error.isAuth) {
          _fail('OpenAI rejected the API key. Check it in Settings.');
        } else {
          state = state.copyWith(error: error.message);
        }
      case TranscriptClosed():
        _onDisconnected();
    }
  }

  /// Deltas can arrive before the commit event that names the item.
  String? _segFor(String itemId) {
    final known = _itemToSeg[itemId];
    if (known != null) return known;
    final seg = _awaitingItemId.isNotEmpty ? _awaitingItemId.removeFirst() : _currentSeg;
    if (seg != null) _itemToSeg[itemId] = seg;
    return seg;
  }

  void _onDisconnected() {
    if (_client == null) return;
    if (state.phase != LivePhase.live && state.phase != LivePhase.stopping) return;
    unawaited(_eventSub?.cancel());
    _eventSub = null;
    _client = null;

    // Anything sent but not transcribed is lost with the old session. Queue
    // it again, oldest first.
    final lost = {..._itemToSeg.values, ..._awaitingItemId}
        .where((s) => _unresolved.contains(s) && _segAudio.containsKey(s));
    _needsResend
      ..addAll(lost.where((s) => !_needsResend.contains(s)))
      ..sort(_bySegNumber);
    _itemToSeg.clear();
    _awaitingItemId.clear();
    state = state.copyWith(reconnecting: true, partials: const {});
    unawaited(_reconnect(_generation));
  }

  Future<void> _reconnect(int generation) async {
    for (var attempt = 0;; attempt++) {
      final delay = _reconnectDelays[attempt.clamp(0, _reconnectDelays.length - 1)];
      await Future<void>.delayed(Duration(seconds: delay));
      if (generation != _generation || !state.active) return;
      try {
        final client = await TranscriptionClient.connect(apiKey: _apiKey, language: _sourceCode);
        if (generation != _generation || !state.active) {
          await client.close();
          return;
        }
        _attach(client);
        _resendBuffered(client);
        state = state.copyWith(reconnecting: false);
        return;
      } on OpenAiException catch (e) {
        if (e.isAuth) {
          _fail('OpenAI rejected the API key. Check it in Settings.');
          return;
        }
      } catch (_) {}
    }
  }

  void _resendBuffered(TranscriptionClient client) {
    for (final seg in _needsResend) {
      final audio = _segAudio[seg]?.toBytes();
      if (audio == null || audio.isEmpty) {
        _unresolved.remove(seg);
        continue;
      }
      for (var i = 0; i < audio.length; i += _resendChunkBytes) {
        final end = i + _resendChunkBytes < audio.length ? i + _resendChunkBytes : audio.length;
        client.appendAudio(Uint8List.sublistView(audio, i, end));
      }
      client.commit();
      _awaitingItemId.add(seg);
    }
    _needsResend.clear();
    final current = _currentSeg;
    if (current != null) {
      final audio = _segAudio[current]?.toBytes();
      if (audio != null && audio.isNotEmpty) client.appendAudio(audio);
    }
  }

  static int _bySegNumber(String a, String b) =>
      int.parse(a.substring(4)).compareTo(int.parse(b.substring(4)));

  void _removePartial(String seg) {
    if (!state.partials.containsKey(seg)) return;
    state = state.copyWith(partials: {...state.partials}..remove(seg));
  }

  Future<void> _translate(String sessionId, String seg, String text) async {
    final translator = _translator;
    if (translator == null) {
      _unresolved.remove(seg);
      return;
    }
    final context = _recent.length > _contextLines
        ? _recent.sublist(_recent.length - _contextLines)
        : List.of(_recent);
    try {
      for (var attempt = 0;; attempt++) {
        try {
          final translated = await translator.translate(
            text: text,
            from: _from,
            to: _to,
            context: context,
          );
          _recent.add((text, translated));
          await _db.updateLine(sessionId, seg, LinesCompanion(translatedText: Value(translated)));
          _speaker?.speak(translated);
          return;
        } on OpenAiException catch (e) {
          if (e.isAuth || attempt >= 2) rethrow;
        } catch (_) {
          if (attempt >= 2) rethrow;
        }
        await Future<void>.delayed(Duration(seconds: attempt == 0 ? 1 : 3));
      }
    } catch (e) {
      if (state.active) state = state.copyWith(error: 'Translation failed: ${_describe(e)}');
    } finally {
      _unresolved.remove(seg);
    }
  }

  Future<void> _nameSession(String id, List<Line> lines, Translator? translator) async {
    try {
      final originals = lines.map((l) => l.originalText).whereType<String>().toList();
      if (translator == null || originals.isEmpty) return;
      final title = await translator.title(originals);
      if (title.isNotEmpty) {
        await _db.updateSession(id, SessionsCompanion(title: Value(title)));
      }
    } catch (_) {
      // Keeps the default title.
    } finally {
      _text?.close();
      _text = null;
    }
  }

  void _fail(String message) {
    if (state.phase != LivePhase.live) return;
    state = state.copyWith(error: message);
    unawaited(stop(reason: message));
  }

  Future<void> _discardIfEmpty(String id) async {
    final s = await (_db.select(_db.sessions)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (s != null && (await _db.linesFor(id)).isEmpty) {
      await deleteSessionWithAudio(_db, s);
    }
  }

  Future<void> _teardown({bool keepText = false}) async {
    _generation++;
    await BackgroundRecording.stop();
    await _micSub?.cancel();
    _micSub = null;
    await _eventSub?.cancel();
    _eventSub = null;
    final recorder = _recorder;
    _recorder = null;
    if (recorder != null) {
      try {
        await recorder.stop();
      } catch (_) {}
      await recorder.dispose();
    }
    await _client?.close();
    _client = null;
    final sink = _sink;
    _sink = null;
    await sink?.close();
    await _speaker?.dispose();
    _speaker = null;
    await _interpreter?.dispose();
    _interpreter = null;
    if (!keepText) {
      _text?.close();
      _text = null;
    }
    _translator = null;
    _vad = null;
    _currentSeg = null;
    _awaitingItemId.clear();
    _itemToSeg.clear();
    _segAudio.clear();
    _needsResend.clear();
    _unresolved.clear();
    _recent.clear();
  }

  String _describe(Object e) => e is OpenAiException ? e.message : e.toString();

  String _micPermissionHelp() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        return 'Microphone access is off. Turn it on for Lt in System Settings → Privacy & Security → Microphone.';
      case TargetPlatform.windows:
        return 'Microphone access is off. Turn on "Let desktop apps access your microphone" in Settings → Privacy & security → Microphone.';
      default:
        return 'Microphone access is off. Allow it for Lt in your device settings.';
    }
  }
}
