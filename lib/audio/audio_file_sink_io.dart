import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'audio_file_sink.dart';
import 'wav_writer.dart';

Future<File> _file(String relativePath) async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, relativePath));
}

Future<AudioFileSink?> openAudioFileSink(String sessionId) async {
  final relative = p.posix.join('audio', '$sessionId.wav');
  final writer = await WavWriter.create(await _file(relative));
  return _WavFileSink(relative, writer);
}

Future<void> deleteAudioFile(String relativePath) async {
  final f = await _file(relativePath);
  if (await f.exists()) await f.delete();
}

Future<int?> repairAudioFile(String relativePath) async {
  final f = await _file(relativePath);
  if (!await f.exists()) return null;
  return WavWriter.repair(f);
}

Future<String?> resolveAudioPath(String relativePath) async =>
    (await _file(relativePath)).path;

class _WavFileSink implements AudioFileSink {
  _WavFileSink(this.relativePath, this._writer) {
    _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _queue = _queue.then((_) => _writer.flush());
    });
  }

  @override
  final String relativePath;
  final WavWriter _writer;
  late final Timer _flushTimer;

  // RandomAccessFile rejects a write while another is pending, so writes are
  // chained.
  Future<void> _queue = Future.value();

  @override
  int get fileBytes => WavWriter.headerBytes + _writer.dataBytes;

  @override
  void append(Uint8List pcm) {
    _queue = _queue.then((_) => _writer.append(pcm));
  }

  @override
  Future<void> close() async {
    _flushTimer.cancel();
    await _queue;
    await _writer.close();
  }
}
