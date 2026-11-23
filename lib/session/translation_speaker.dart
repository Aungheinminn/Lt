import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import '../audio/bytes_source.dart';
import '../openai/text_client.dart';

/// Reads translated lines aloud in order. Speech for each line is requested
/// as soon as it is queued, so the next line is usually ready when the
/// current one finishes.
class TranslationSpeaker {
  TranslationSpeaker(this._client, {this.onSpoken});

  final OpenAiTextClient _client;

  /// Length of each generated clip; speech is billed by audio produced.
  final void Function(Duration length)? onSpoken;
  // Without session activation the player doesn't take audio focus, so
  // whatever else is playing (the speaker the user may be translating) goes on.
  final _player = AudioPlayer(handleAudioSessionActivation: false, handleInterruptions: false);
  final _queue = Queue<Future<Uint8List?>>();
  bool _running = false;
  bool _disposed = false;
  DateTime _quietSince = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isSpeaking => _running;

  /// True while speaking and briefly after, so the mic doesn't transcribe
  /// the app's own voice.
  bool get suppressMic =>
      _running || DateTime.now().difference(_quietSince) < const Duration(milliseconds: 400);

  void speak(String text) {
    if (_disposed || text.trim().isEmpty) return;
    _queue.add(_client.speech(text).then<Uint8List?>((b) => b).catchError((_) => null));
    if (!_running) unawaited(_pump());
  }

  Future<void> _pump() async {
    _running = true;
    try {
      while (_queue.isNotEmpty && !_disposed) {
        final bytes = await _queue.removeFirst();
        if (bytes == null || _disposed) continue;
        final source = await mp3Source(bytes);
        try {
          final length = await _player.setAudioSource(source);
          if (length != null) onSpoken?.call(length);
          await _player.play();
          await _player.playerStateStream.firstWhere(
            (s) => s.processingState == ProcessingState.completed || !s.playing,
          );
        } catch (_) {
          // Skip a line that fails to play.
        } finally {
          await _player.stop();
          await releaseSource(source);
        }
      }
    } finally {
      _running = false;
      _quietSince = DateTime.now();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _queue.clear();
    await _player.dispose();
  }
}
