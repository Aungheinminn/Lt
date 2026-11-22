import 'dart:typed_data';

import 'audio_file_sink_stub.dart'
    if (dart.library.io) 'audio_file_sink_io.dart' as impl;

/// Session audio written to disk. Not available on the web, where these
/// functions return null.
abstract class AudioFileSink {
  /// Relative to the app support directory; this is what the database stores.
  String get relativePath;

  /// Size of the finished file including the WAV header.
  int get fileBytes;

  /// Queues [pcm] for writing. Calls may overlap; writes stay in order.
  void append(Uint8List pcm);

  Future<void> close();
}

Future<AudioFileSink?> openAudioFileSink(String sessionId) =>
    impl.openAudioFileSink(sessionId);

Future<void> deleteAudioFile(String relativePath) =>
    impl.deleteAudioFile(relativePath);

/// Fixes the header of a file left open by a crash. Returns its duration.
Future<int?> repairAudioFile(String relativePath) =>
    impl.repairAudioFile(relativePath);

/// Absolute path for playback, or null on the web.
Future<String?> resolveAudioPath(String relativePath) =>
    impl.resolveAudioPath(relativePath);
