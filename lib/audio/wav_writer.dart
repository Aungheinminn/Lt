import 'dart:io';
import 'dart:typed_data';

/// Streams PCM16 mono audio to a WAV file. The format matches what the
/// OpenAI Realtime API takes, so the same bytes go to both.
class WavWriter {
  WavWriter._(this._file);

  static const sampleRate = 24000;
  static const channels = 1;
  static const bitsPerSample = 16;
  static const headerBytes = 44;
  static const bytesPerMs = sampleRate * channels * bitsPerSample ~/ 8 ~/ 1000;

  final RandomAccessFile _file;
  int _dataBytes = 0;

  int get dataBytes => _dataBytes;
  int get durationMs => _dataBytes ~/ bytesPerMs;

  static Future<WavWriter> create(File file) async {
    await file.parent.create(recursive: true);
    final raf = await file.open(mode: FileMode.write);
    await raf.writeFrom(header(0));
    return WavWriter._(raf);
  }

  Future<void> append(Uint8List pcm) async {
    await _file.writeFrom(pcm);
    _dataBytes += pcm.length;
  }

  Future<void> flush() => _file.flush();

  Future<void> close() async {
    await _file.setPosition(0);
    await _file.writeFrom(header(_dataBytes));
    await _file.close();
  }

  /// Rewrites the header of a file whose writer never closed (app killed
  /// mid-recording). Drops a trailing half sample if there is one.
  static Future<int> repair(File file) async {
    final length = await file.length();
    if (length < headerBytes) return 0;
    var dataLen = length - headerBytes;
    dataLen -= dataLen % (bitsPerSample ~/ 8);
    final raf = await file.open(mode: FileMode.append);
    try {
      await raf.truncate(headerBytes + dataLen);
      await raf.setPosition(0);
      await raf.writeFrom(header(dataLen));
    } finally {
      await raf.close();
    }
    return dataLen ~/ bytesPerMs;
  }

  static Uint8List header(int dataLen) {
    final b = ByteData(headerBytes);
    void tag(int offset, String s) {
      for (var i = 0; i < 4; i++) {
        b.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    const blockAlign = channels * bitsPerSample ~/ 8;
    tag(0, 'RIFF');
    b.setUint32(4, 36 + dataLen, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little);
    b.setUint16(22, channels, Endian.little);
    b.setUint32(24, sampleRate, Endian.little);
    b.setUint32(28, sampleRate * blockAlign, Endian.little);
    b.setUint16(32, blockAlign, Endian.little);
    b.setUint16(34, bitsPerSample, Endian.little);
    tag(36, 'data');
    b.setUint32(40, dataLen, Endian.little);
    return b.buffer.asUint8List();
  }
}
