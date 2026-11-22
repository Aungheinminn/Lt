import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import 'bytes_source_web.dart' if (dart.library.io) 'bytes_source_io.dart' as impl;

/// A playable source for in-memory MP3 audio. Native players can't open
/// data: URIs reliably, so native platforms go through a temp file.
Future<AudioSource> mp3Source(Uint8List bytes) => impl.mp3Source(bytes);

/// Removes any temp file behind [source].
Future<void> releaseSource(AudioSource source) => impl.releaseSource(source);
