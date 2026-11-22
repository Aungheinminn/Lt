import 'dart:math' as math;
import 'dart:typed_data';

sealed class VadEvent {}

/// Speech began. [preRoll] is the audio just before detection, so the first
/// syllable isn't clipped.
class VadSpeechStart extends VadEvent {
  VadSpeechStart(this.startMs, this.preRoll);
  final int startMs;
  final Uint8List preRoll;
}

/// Audio that belongs to the current speech segment.
class VadAudio extends VadEvent {
  VadAudio(this.bytes);
  final Uint8List bytes;
}

class VadSpeechEnd extends VadEvent {
  VadSpeechEnd(this.endMs, this.voicedMs);
  final int endMs;

  /// Time above the speech threshold; short blips (coughs, clicks) are
  /// discarded by the caller.
  final int voicedMs;
}

/// Energy-based voice activity detection over PCM16 mono 24 kHz audio. All
/// times are milliseconds from the first byte processed, which is the same
/// clock as the session's WAV file.
class Vad {
  Vad({
    this.preRollMs = 300,
    this.hangoverMs = 700,
    this.maxSegmentMs = 15000,
  });

  static const sampleRate = 24000;
  static const frameMs = 20;
  static const frameBytes = sampleRate * 2 * frameMs ~/ 1000;
  static const _startFrames = 3;

  final int preRollMs;
  final int hangoverMs;
  final int maxSegmentMs;

  final _pending = BytesBuilder(copy: true);
  final _preRoll = <Uint8List>[];
  int _framesProcessed = 0;
  double _noiseFloor = 200;
  bool _inSpeech = false;
  int _loudRun = 0;
  int _silentRun = 0;
  int _segmentStartMs = 0;
  int _voicedFrames = 0;
  int _lastVoicedEndMs = 0;
  double _level = 0;

  bool get inSpeech => _inSpeech;

  /// Smoothed input level from 0 to 1, for a mic meter.
  double get level => _level;

  int get _nowMs => _framesProcessed * frameMs;

  List<VadEvent> process(Uint8List chunk) {
    _pending.add(chunk);
    final all = _pending.takeBytes();
    final events = <VadEvent>[];
    var offset = 0;
    while (offset + frameBytes <= all.length) {
      final frame = Uint8List.sublistView(all, offset, offset + frameBytes);
      _processFrame(Uint8List.fromList(frame), events);
      offset += frameBytes;
    }
    if (offset < all.length) _pending.add(Uint8List.sublistView(all, offset));
    return events;
  }

  /// Ends any open segment, e.g. when the user presses Stop.
  List<VadEvent> flush() {
    if (!_inSpeech) return const [];
    _inSpeech = false;
    return [VadSpeechEnd(_nowMs, _voicedFrames * frameMs)];
  }

  void _processFrame(Uint8List frame, List<VadEvent> out) {
    final rms = _rms(frame);
    _level = _level * 0.7 + math.min(1.0, rms / 6000) * 0.3;

    final startThreshold = math.max(_noiseFloor * 3, 500.0);
    final stayThreshold = math.max(_noiseFloor * 2, 350.0);

    if (!_inSpeech) {
      _preRoll.add(frame);
      while (_preRoll.length * frameMs > preRollMs + _startFrames * frameMs) {
        _preRoll.removeAt(0);
      }
      if (rms > startThreshold) {
        _loudRun++;
      } else {
        _loudRun = 0;
        _noiseFloor = _noiseFloor * 0.95 + rms * 0.05;
      }
      _framesProcessed++;
      if (_loudRun >= _startFrames) {
        _beginSegment(out);
      }
      return;
    }

    _framesProcessed++;
    out.add(VadAudio(frame));
    if (rms > stayThreshold) {
      _silentRun = 0;
      _voicedFrames++;
      _lastVoicedEndMs = _nowMs;
    } else {
      _silentRun++;
    }

    final tooLong = _nowMs - _segmentStartMs >= maxSegmentMs;
    if (_silentRun * frameMs >= hangoverMs || tooLong) {
      _inSpeech = false;
      final endMs = tooLong ? _nowMs : math.min(_nowMs, _lastVoicedEndMs + 200);
      out.add(VadSpeechEnd(endMs, _voicedFrames * frameMs));
      _loudRun = tooLong && rms > startThreshold ? _startFrames : 0;
      _preRoll.clear();
      if (tooLong && _loudRun >= _startFrames) _beginSegment(out);
    }
  }

  void _beginSegment(List<VadEvent> out) {
    final bytes = BytesBuilder(copy: false);
    for (final f in _preRoll) {
      bytes.add(f);
    }
    final preRoll = bytes.takeBytes();
    _segmentStartMs = math.max(0, _nowMs - preRoll.length ~/ (sampleRate * 2 ~/ 1000));
    _preRoll.clear();
    _inSpeech = true;
    _silentRun = 0;
    _voicedFrames = _startFrames;
    _lastVoicedEndMs = _nowMs;
    out.add(VadSpeechStart(_segmentStartMs, preRoll));
  }

  static double _rms(Uint8List frame) {
    final data = ByteData.sublistView(frame);
    var sum = 0.0;
    final n = frame.length ~/ 2;
    for (var i = 0; i < n; i++) {
      final s = data.getInt16(i * 2, Endian.little).toDouble();
      sum += s * s;
    }
    return n == 0 ? 0 : math.sqrt(sum / n);
  }
}
