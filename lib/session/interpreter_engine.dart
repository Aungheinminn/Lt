import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import '../audio/pcm_player.dart';
import '../audio/wav_writer.dart';
import '../data/db/app_database.dart';
import '../openai/openai_error.dart';
import '../openai/translation_client.dart';

/// Interpreter mode: streams the mic to gpt-realtime-translate and plays the
/// translated voice as it comes back.
///
/// The model returns one continuous transcript per side, with no sentence
/// boundaries. Lines come from the on-device speech detector, and each
/// transcript delta is placed on the line covering its `elapsed_ms`, so the
/// pairing of original and translation is approximate.
class InterpreterEngine {
  InterpreterEngine({
    required this._db,
    required this.sessionId,
    required this._apiKey,
    required String targetLanguage,
    required this.onReconnecting,
    required this.onError,
    required this.onFatal,
  }) : _target = targetLanguage;

  static const _sendChunkBytes = 9600; // 200 ms, the model's frame size
  static const _lineTolerance = 400;
  static const _newLineGapMs = 1500;
  static const _reconnectDelays = [1, 2, 4, 8, 15, 30];

  final AppDatabase _db;
  final String sessionId;
  final String _apiKey;
  final String _target;
  final void Function(bool reconnecting) onReconnecting;
  final void Function(String message) onError;
  final void Function(String message) onFatal;

  final _player = PcmPlayer();
  final _pending = BytesBuilder(copy: false);
  TranslationClient? _client;
  StreamSubscription<InterpreterEvent>? _sub;
  bool _disposed = false;
  bool _closing = false;
  Completer<void>? _closed;

  int _fileMs = 0;

  /// File position of the first byte sent on the current connection; the
  /// model's clock restarts at 0 on every connection.
  int _connectionStartMs = 0;

  final _lines = <_LineRef>[];
  int _autoCounter = 0;

  bool get suppressMic => _player.audible;

  Future<void> connect() async {
    _player.open();
    _attach(await TranslationClient.connect(apiKey: _apiKey, targetLanguage: _target));
  }

  void _attach(TranslationClient client) {
    _client = client;
    _pending.clear();
    _connectionStartMs = _fileMs;
    _sub = client.events.listen(_onEvent);
  }

  /// [pcm] is what the speech detector saw: real mic audio, or silence while
  /// the translated voice is playing.
  void addAudio(Uint8List pcm) {
    _fileMs += pcm.length ~/ WavWriter.bytesPerMs;
    final client = _client;
    if (client == null || _closing) return;
    _pending.add(pcm);
    if (_pending.length >= _sendChunkBytes) client.appendAudio(_pending.takeBytes());
  }

  void lineStarted(String seg, int startMs) {
    _lines.add(_LineRef(seg, startMs));
    _db.createLine(sessionId, seg, startMs);
  }

  void lineEnded(String seg, int endMs) {
    for (final l in _lines.reversed) {
      if (l.seg == seg) {
        l.endMs = endMs;
        break;
      }
    }
    _db.updateLine(sessionId, seg, LinesCompanion(endMs: Value(endMs)));
  }

  /// A noise blip with no transcript is dropped; one that got text is kept.
  void lineDiscarded(String seg) {
    final i = _lines.indexWhere((l) => l.seg == seg);
    if (i < 0 || _lines[i].original.isNotEmpty || _lines[i].translated.isNotEmpty) return;
    _lines.removeAt(i);
    _db.deleteLine(sessionId, seg);
  }

  void _onEvent(InterpreterEvent e) {
    switch (e) {
      case InputTranscript(:final delta, :final elapsedMs):
        if (delta.isEmpty) return;
        final line = _lineFor(elapsedMs);
        line.original.write(delta);
        _db.updateLine(sessionId, line.seg,
            LinesCompanion(originalText: Value(line.original.toString().trim())));
      case OutputTranscript(:final delta, :final elapsedMs):
        if (delta.isEmpty) return;
        final line = _lineFor(elapsedMs);
        line.translated.write(delta);
        _db.updateLine(sessionId, line.seg,
            LinesCompanion(translatedText: Value(line.translated.toString().trim())));
      case OutputAudio(:final pcm):
        _player.push(pcm);
      case InterpreterError(:final error):
        if (error.isAuth) {
          onFatal('OpenAI rejected the API key. Check it in Settings.');
        } else {
          onError(error.message);
        }
      case InterpreterClosed():
        _onClosed();
    }
  }

  _LineRef _lineFor(int? elapsedMs) {
    final at = elapsedMs == null ? _fileMs : _connectionStartMs + elapsedMs;
    _LineRef? match;
    for (final l in _lines.reversed) {
      if (l.startMs <= at + _lineTolerance) {
        match = l;
        break;
      }
    }
    // Speech the detector missed (quiet voice) still gets its own line.
    final stale = match != null && match.endMs != null && at - match.endMs! > _newLineGapMs;
    if (match == null || stale) {
      final seg = 'auto_${_autoCounter++}';
      final ref = _LineRef(seg, at);
      final index = _lines.indexWhere((l) => l.startMs > at);
      index < 0 ? _lines.add(ref) : _lines.insert(index, ref);
      _db.createLine(sessionId, seg, at);
      return ref;
    }
    return match;
  }

  void _onClosed() {
    unawaited(_sub?.cancel());
    _sub = null;
    _client = null;
    if (_closing) {
      _closed?.complete();
      return;
    }
    if (_disposed) return;
    onReconnecting(true);
    unawaited(_reconnect());
  }

  Future<void> _reconnect() async {
    for (var attempt = 0;; attempt++) {
      final delay = _reconnectDelays[attempt.clamp(0, _reconnectDelays.length - 1)];
      await Future<void>.delayed(Duration(seconds: delay));
      if (_disposed || _closing) return;
      try {
        final client = await TranslationClient.connect(apiKey: _apiKey, targetLanguage: _target);
        if (_disposed || _closing) {
          await client.close();
          return;
        }
        _attach(client);
        onReconnecting(false);
        return;
      } on OpenAiException catch (e) {
        if (e.isAuth) {
          onFatal('OpenAI rejected the API key. Check it in Settings.');
          return;
        }
      } catch (_) {}
    }
  }

  /// Sends what's left, lets the server flush its last translation, then
  /// lets the voice finish playing.
  Future<void> finish() async {
    _closing = true;
    final client = _client;
    if (client != null) {
      if (_pending.length > 0) client.appendAudio(_pending.takeBytes());
      _closed = Completer<void>();
      client.requestClose();
      await _closed!.future.timeout(const Duration(seconds: 6), onTimeout: () {});
    }
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (_player.audible && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _closing = true;
    await _sub?.cancel();
    _sub = null;
    await _client?.close();
    _client = null;
    _player.close();
  }
}

class _LineRef {
  _LineRef(this.seg, this.startMs);

  final String seg;
  final int startMs;
  int? endMs;
  final original = StringBuffer();
  final translated = StringBuffer();
}
