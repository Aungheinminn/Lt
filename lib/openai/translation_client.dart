import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'openai_error.dart';

sealed class InterpreterEvent {}

class InputTranscript extends InterpreterEvent {
  InputTranscript(this.delta, this.elapsedMs);
  final String delta;
  final int? elapsedMs;
}

class OutputTranscript extends InterpreterEvent {
  OutputTranscript(this.delta, this.elapsedMs);
  final String delta;
  final int? elapsedMs;
}

class OutputAudio extends InterpreterEvent {
  OutputAudio(this.pcm);
  final Uint8List pcm;
}

class InterpreterError extends InterpreterEvent {
  InterpreterError(this.error);
  final OpenAiException error;
}

class InterpreterClosed extends InterpreterEvent {}

/// OpenAI realtime speech-to-speech translation session. Audio goes in as a
/// continuous stream (silence included); translated audio and transcript
/// deltas come back while the speaker is still talking.
class TranslationClient {
  TranslationClient._(this._channel, this.events);

  static const model = 'gpt-realtime-translate';
  static const transcriptionModel = 'gpt-realtime-whisper';

  final WebSocketChannel _channel;
  final Stream<InterpreterEvent> events;

  static Future<TranslationClient> connect({
    required String apiKey,
    required String targetLanguage,
  }) async {
    final uri = Uri.parse('wss://api.openai.com/v1/realtime/translations?model=$model');
    final channel = WebSocketChannel.connect(uri, protocols: [
      'realtime',
      'openai-insecure-api-key.$apiKey',
    ]);
    try {
      await channel.ready;
    } catch (_) {
      throw OpenAiException(
        'Could not connect to OpenAI. Check your internet connection and API key.',
      );
    }

    final controller = StreamController<_Parsed>.broadcast();
    channel.stream.listen(
      (raw) {
        final parsed = _parse(raw);
        if (parsed != null) controller.add(parsed);
      },
      onError: (_) => controller.add(_Parsed(InterpreterClosed())),
      onDone: () {
        controller.add(_Parsed(InterpreterClosed()));
        controller.close();
      },
    );

    channel.sink.add(jsonEncode({
      'type': 'session.update',
      'session': {
        'audio': {
          'input': {
            'transcription': {'model': transcriptionModel},
            'noise_reduction': {'type': 'near_field'},
          },
          'output': {'language': targetLanguage},
        },
      },
    }));

    final first = await controller.stream
        .firstWhere((e) => e.ready || e.event is InterpreterError || e.event is InterpreterClosed)
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw OpenAiException('OpenAI did not respond. Try again.');
    });
    if (!first.ready) {
      await channel.sink.close();
      final e = first.event;
      throw e is InterpreterError ? e.error : OpenAiException('Connection to OpenAI closed.');
    }

    return TranslationClient._(
      channel,
      controller.stream.where((e) => e.event != null).map((e) => e.event!),
    );
  }

  void appendAudio(Uint8List pcm) => _send({
        'type': 'session.input_audio_buffer.append',
        'audio': base64Encode(pcm),
      });

  /// Asks the server to flush remaining output, then close.
  void requestClose() => _send({'type': 'session.close'});

  Future<void> close() => _channel.sink.close();

  void _send(Map<String, Object?> event) => _channel.sink.add(jsonEncode(event));

  static _Parsed? _parse(dynamic raw) {
    if (raw is! String) return null;
    final Map<String, dynamic> m;
    try {
      m = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    int? elapsed() => (m['elapsed_ms'] as num?)?.toInt();
    switch (m['type']) {
      case 'session.created':
      case 'session.updated':
        return _Parsed.ready();
      case 'session.input_transcript.delta':
        return _Parsed(InputTranscript(m['delta'] as String? ?? '', elapsed()));
      case 'session.output_transcript.delta':
        return _Parsed(OutputTranscript(m['delta'] as String? ?? '', elapsed()));
      case 'session.output_audio.delta':
        final b64 = m['delta'] as String?;
        return b64 == null ? null : _Parsed(OutputAudio(base64Decode(b64)));
      case 'error':
        final err = m['error'] as Map<String, dynamic>? ?? const {};
        return _Parsed(InterpreterError(OpenAiException(
          err['message'] as String? ?? 'Unknown OpenAI error',
          code: err['code'] as String?,
        )));
      default:
        return const _Parsed(null);
    }
  }
}

class _Parsed {
  const _Parsed(this.event) : ready = false;
  const _Parsed.ready()
      : event = null,
        ready = true;

  final InterpreterEvent? event;
  final bool ready;
}
