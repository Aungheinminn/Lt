import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

Future<AudioSource> mp3Source(Uint8List bytes) async =>
    AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg'));

Future<void> releaseSource(AudioSource source) async {}
