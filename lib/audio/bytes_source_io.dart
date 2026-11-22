import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

int _counter = 0;

Future<AudioSource> mp3Source(Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, 'lt_tts_${pid}_${_counter++}.mp3'));
  await file.writeAsBytes(bytes, flush: true);
  return AudioSource.file(file.path);
}

Future<void> releaseSource(AudioSource source) async {
  if (source is! UriAudioSource || source.uri.scheme != 'file') return;
  final file = File.fromUri(source.uri);
  if (await file.exists()) await file.delete();
}
