import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';

/// Plays a live stream of PCM16 mono 24 kHz audio as it arrives.
class PcmPlayer {
  static const sampleRate = 24000;

  final _stream = getAudioStream();
  DateTime _playingUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _open = false;

  /// Must be called from a user action on the web, where browsers only allow
  /// audio after a tap or click.
  void open() {
    _stream.init(
      sampleRate: sampleRate,
      channels: 1,
      bufferMilliSec: 30000,
      waitingBufferMilliSec: 150,
      fadeOnExhaust: true,
    );
    _stream.resume();
    _open = true;
  }

  /// True while queued audio is still playing, plus a short tail for room
  /// echo.
  bool get audible =>
      DateTime.now().isBefore(_playingUntil.add(const Duration(milliseconds: 300)));

  void push(Uint8List pcm16) {
    if (!_open || pcm16.length < 2) return;
    final data = ByteData.sublistView(pcm16);
    final samples = Float32List(pcm16.length ~/ 2);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    _stream.push(samples);

    final now = DateTime.now();
    final start = _playingUntil.isAfter(now) ? _playingUntil : now;
    _playingUntil = start.add(Duration(microseconds: samples.length * 1000000 ~/ sampleRate));
  }

  void close() {
    if (!_open) return;
    _open = false;
    _stream.uninit();
  }
}
