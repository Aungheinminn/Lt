import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lt/audio/vad.dart';

Uint8List _tone(int ms, {double amplitude = 4000}) {
  final n = 24 * ms;
  final b = ByteData(n * 2);
  for (var i = 0; i < n; i++) {
    b.setInt16(i * 2, (amplitude * math.sin(2 * math.pi * 220 * i / 24000)).round(), Endian.little);
  }
  return b.buffer.asUint8List();
}

Uint8List _silence(int ms) => Uint8List(24 * ms * 2);

/// Steady background sound with the given RMS level.
Uint8List _noise(int ms, double rms, {int seed = 1}) {
  final r = math.Random(seed);
  final amp = rms * math.sqrt(3);
  final b = ByteData(24 * ms * 2);
  for (var i = 0; i < 24 * ms; i++) {
    b.setInt16(i * 2, ((r.nextDouble() * 2 - 1) * amp).round(), Endian.little);
  }
  return b.buffer.asUint8List();
}

Uint8List _mix(Uint8List a, Uint8List b) {
  final x = ByteData.sublistView(a), y = ByteData.sublistView(b), o = ByteData(a.length);
  for (var i = 0; i < a.length; i += 2) {
    final v = x.getInt16(i, Endian.little) + y.getInt16(i, Endian.little);
    o.setInt16(i, v.clamp(-32768, 32767), Endian.little);
  }
  return o.buffer.asUint8List();
}

List<VadEvent> _feed(Vad vad, List<Uint8List> parts, {int chunkMs = 100}) {
  final all = BytesBuilder()..addAll(parts);
  final bytes = all.takeBytes();
  final chunk = 24 * chunkMs * 2 + 6; // deliberately not frame-aligned
  final events = <VadEvent>[];
  for (var i = 0; i < bytes.length; i += chunk) {
    events.addAll(vad.process(Uint8List.sublistView(bytes, i, math.min(i + chunk, bytes.length))));
  }
  return events;
}

extension on BytesBuilder {
  void addAll(List<Uint8List> parts) => parts.forEach(add);
}

void main() {
  test('detects one sentence with start and end on the file clock', () {
    final events = _feed(Vad(), [_silence(1000), _tone(1500), _silence(1500)]);

    final start = events.whereType<VadSpeechStart>().single;
    final end = events.whereType<VadSpeechEnd>().single;
    expect(start.startMs, inInclusiveRange(450, 1000));
    expect(start.preRoll, isNotEmpty);
    expect(end.endMs, inInclusiveRange(2400, 2800));
    expect(end.voicedMs, greaterThan(1200));
  });

  test('audio sent to OpenAI covers only the speech segment', () {
    final events = _feed(Vad(), [_silence(2000), _tone(1000), _silence(2000)]);

    final start = events.whereType<VadSpeechStart>().single;
    final audioBytes = events.whereType<VadAudio>().fold<int>(0, (n, a) => n + a.bytes.length);
    final sentMs = (start.preRoll.length + audioBytes) ~/ 48;
    expect(sentMs, lessThan(2400));
    expect(sentMs, greaterThan(1000));
  });

  test('quiet or distant speech still starts a sentence', () {
    // Amplitude 400 is RMS ~280, typical of a voice across a room.
    final events = _feed(Vad(), [_silence(2000), _tone(2000, amplitude: 400), _silence(1500)]);
    expect(events.whereType<VadSpeechStart>(), hasLength(1));
    expect(events.whereType<VadSpeechEnd>(), hasLength(1));
  });

  test('speech over steady background sound is detected', () {
    final events = _feed(Vad(), [
      _noise(3000, 400),
      _mix(_noise(2000, 400, seed: 2), _tone(2000, amplitude: 1200)),
      _noise(1500, 400, seed: 3),
    ]);
    expect(events.whereType<VadSpeechStart>(), hasLength(1));
  });

  test('steady background sound alone does not start a sentence', () {
    expect(_feed(Vad(), [_noise(6000, 400)]).whereType<VadSpeechStart>(), isEmpty);
  });

  test('silence produces no events', () {
    expect(_feed(Vad(), [_silence(3000)]), isEmpty);
  });

  test('long speech is split at the maximum segment length', () {
    final events = _feed(Vad(maxSegmentMs: 3000), [_silence(500), _tone(7000), _silence(1500)]);

    expect(events.whereType<VadSpeechStart>().length, 3);
    expect(events.whereType<VadSpeechEnd>().length, 3);
  });

  test('flush closes an open segment', () {
    final vad = Vad();
    _feed(vad, [_silence(500), _tone(800)]);
    expect(vad.inSpeech, isTrue);

    final end = vad.flush().single as VadSpeechEnd;
    expect(end.endMs, closeTo(1300, 30));
    expect(vad.inSpeech, isFalse);
  });
}
