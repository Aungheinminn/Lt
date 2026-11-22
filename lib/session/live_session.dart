import 'dart:async';
import 'dart:collection';

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
import 'session_storage.dart';

enum LivePhase { idle, connecting, live, stopping }

@immutable
class LiveState {
  const LiveState({
    this.phase = LivePhase.idle,
    this.sessionId,
    this.elapsedMs = 0,
    this.level = 0,
    this.speaking = false,
    this.partials = const {},
    this.error,
    this.savedSessionId,
  });

  final LivePhase phase;
  final String? sessionId;
  final int elapsedMs;
  final double level;
  final bool speaking;

  /// In-progress transcript text by segment key, before the final arrives.
  final Map<String, String> partials;
  final String? error;

  /// Set after Stop when a session was saved, so the UI can offer to open it.
  final String? savedSessionId;

  bool get active => phase != LivePhase.idle;

  LiveState copyWith({
    int? elapsedMs,
    double? level,
    bool? speaking,
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
      partials: partials ?? this.partials,
      error: clearError ? null : error ?? this.error,
      savedSessionId: savedSessionId,
    );
  }
}

final liveSessionProvider =
    NotifierProvider<LiveSessionController, LiveState>(LiveSessionController.new);

class LiveSessionController extends Notifier<LiveState> {
  static const _minVoicedMs = 250;
  static const _contextLines = 3;

  AppDatabase get _db => ref.read(databaseProvider);

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<TranscriptionEvent>? _eventSub;
  TranscriptionClient? _client;
  OpenAiTextClient? _text;
  Translator? _translator;
  AudioFileSink? _sink;
  Vad? _vad;

  String? _sessionId;
  String _from = '';
  String _to = '';
  int _bytes = 0;
  int _segCounter = 0;
  String? _currentSeg;

  /// Segments committed to OpenAI, oldest first, waiting for their item id.
  final _awaitingItemId = Queue<String>();
  final _itemToSeg = <String, String>{};

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
    _from = languageFor(settings.sourceLang).name;
    _to = languageFor(settings.targetLang).name;
    state = const LiveState(phase: LivePhase.connecting);

    try {
      final recorder = _recorder = AudioRecorder();
      if (!await recorder.hasPermission()) {
        throw OpenAiException(_micPermissionHelp());
      }

      final client = _client = await TranscriptionClient.connect(
        apiKey: key,
        language: settings.sourceLang,
      );
      _text = OpenAiTextClient(key);
      _translator = Translator(_text!);

      final id = _sessionId = const Uuid().v4();
      _sink = settings.saveAudio ? await openAudioFileSink(id) : null;
      await _db.createSession(
        id: id,
        sourceLang: settings.sourceLang,
        targetLang: settings.targetLang,
        audioPath: _sink?.relativePath,
      );

      _vad = Vad();
      _bytes = 0;
      _segCounter = 0;
      _eventSub = client.events.listen(_onEvent);

      final mic = await recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: WavWriter.sampleRate,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
      ));
      _micSub = mic.listen(
        _onAudio,
        onError: (Object e) => _fail('Microphone stopped: $e'),
      );
      state = LiveState(phase: LivePhase.live, sessionId: id);
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

    // Give in-flight transcripts and translations a moment to land.
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (_unresolved.isNotEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    final sink = _sink;
    _sink = null;
    await sink?.close();
    final translator = _translator;
    await _teardown(keepText: true);

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
    state = LiveState(savedSessionId: id, error: reason);
    unawaited(_nameSession(id, lines, translator));
  }

  void _onAudio(Uint8List chunk) {
    final pcm = Uint8List.fromList(chunk);
    _sink?.append(pcm);
    _bytes += pcm.length;
    final vad = _vad!;
    for (final e in vad.process(pcm)) {
      _handleVad(e);
    }
    state = state.copyWith(
      elapsedMs: _bytes ~/ WavWriter.bytesPerMs,
      level: vad.level,
      speaking: vad.inSpeech,
    );
  }

  void _handleVad(VadEvent e) {
    final client = _client;
    final id = _sessionId;
    if (client == null || id == null) return;
    switch (e) {
      case VadSpeechStart(:final startMs, :final preRoll):
        final seg = 'seg_${_segCounter++}';
        _currentSeg = seg;
        _db.createLine(id, seg, startMs);
        if (preRoll.isNotEmpty) client.appendAudio(preRoll);
      case VadAudio(:final bytes):
        client.appendAudio(bytes);
      case VadSpeechEnd(:final endMs, :final voicedMs):
        final seg = _currentSeg;
        _currentSeg = null;
        if (seg == null) return;
        if (voicedMs < _minVoicedMs) {
          client.clear();
          _db.deleteLine(id, seg);
          return;
        }
        client.commit();
        if (!_itemToSeg.containsValue(seg)) _awaitingItemId.add(seg);
        _unresolved.add(seg);
        _db.updateLine(id, seg, LinesCompanion(endMs: Value(endMs)));
    }
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
      case TranscriptCompleted(:final itemId, :final transcript):
        final seg = _segFor(itemId);
        if (seg == null) return;
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
        if (state.phase == LivePhase.live) _fail('Connection to OpenAI was lost.');
    }
  }

  /// Deltas can arrive for the segment still being spoken, before its commit
  /// gives us the item id.
  String? _segFor(String itemId) {
    final known = _itemToSeg[itemId];
    if (known != null) return known;
    final seg = _awaitingItemId.isNotEmpty ? _awaitingItemId.removeFirst() : _currentSeg;
    if (seg != null) _itemToSeg[itemId] = seg;
    return seg;
  }

  void _removePartial(String seg) {
    if (!state.partials.containsKey(seg)) return;
    state = state.copyWith(partials: {...state.partials}..remove(seg));
  }

  Future<void> _translate(String sessionId, String seg, String text) async {
    try {
      final translated = await _translator!.translate(
        text: text,
        from: _from,
        to: _to,
        context: _recent.length > _contextLines
            ? _recent.sublist(_recent.length - _contextLines)
            : List.of(_recent),
      );
      _recent.add((text, translated));
      await _db.updateLine(sessionId, seg, LinesCompanion(translatedText: Value(translated)));
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
    if (!keepText) {
      _text?.close();
      _text = null;
    }
    _translator = null;
    _vad = null;
    _currentSeg = null;
    _awaitingItemId.clear();
    _itemToSeg.clear();
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
