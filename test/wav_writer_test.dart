import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lt/audio/wav_writer.dart';

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('wav_test'));
  tearDown(() => dir.delete(recursive: true));

  int u32(Uint8List b, int o) => ByteData.sublistView(b).getUint32(o, Endian.little);

  test('header is a valid 24 kHz mono PCM16 WAV', () {
    final h = WavWriter.header(48000);
    expect(String.fromCharCodes(h.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(h.sublist(8, 12)), 'WAVE');
    expect(u32(h, 24), 24000);
    expect(u32(h, 28), 48000);
    expect(u32(h, 40), 48000);
    expect(u32(h, 4), 36 + 48000);
  });

  test('close writes real sizes and duration matches bytes', () async {
    final file = File('${dir.path}/a/s.wav');
    final w = await WavWriter.create(file);
    await w.append(Uint8List(4800));
    await w.append(Uint8List(4800));
    expect(w.durationMs, 200);
    await w.close();

    final bytes = await file.readAsBytes();
    expect(bytes.length, 44 + 9600);
    expect(u32(bytes, 40), 9600);
  });

  test('repair fixes header of an unclosed file and drops half samples', () async {
    final file = File('${dir.path}/crash.wav');
    await file.writeAsBytes([...WavWriter.header(0), ...Uint8List(4801)]);

    final ms = await WavWriter.repair(file);

    final bytes = await file.readAsBytes();
    expect(bytes.length, 44 + 4800);
    expect(u32(bytes, 40), 4800);
    expect(ms, 100);
  });
}
