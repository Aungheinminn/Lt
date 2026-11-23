import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'openai_error.dart';

sealed class TranscriptionEvent {}

class TranscriptCommitted extends TranscriptionEvent {
  TranscriptCommitted(this.itemId);
  final String itemId;
}

class TranscriptDelta extends TranscriptionEvent {
  TranscriptDelta(this.itemId, this.delta);
  final String itemId;
  final String delta;
}

class TranscriptCompleted extends TranscriptionEvent {
  TranscriptCompleted(this.itemId, this.transcript, {this.billedSeconds = 0});
  final String itemId;
  final String transcript;

  /// Audio duration OpenAI billed for this item.
  final double billedSeconds;
}

class TranscriptFailed extends TranscriptionEvent {
  TranscriptFailed(this.itemId, this.message);
  final String itemId;
  final String message;
}

class TranscriptError extends TranscriptionEvent {
  TranscriptError(this.error);
  final OpenAiException error;
}

class TranscriptClosed extends TranscriptionEvent {}

/// OpenAI Realtime transcription session with manual commits: the app
/// decides where each sentence ends (see Vad) and commits it.
class TranscriptionClient {
  TranscriptionClient._(this._channel, this.events);

  static const model = 'gpt-live-transcribe';
  static final _uri =
      Uri.parse('wss://api.openai.com/v1/realtime?intent=transcription');

  final WebSocketChannel _channel;
  final Stream<TranscriptionEvent> events;

  static Future<TranscriptionClient> connect({
    required String apiKey,
    String? language,
  }) async {
    try {
      return await _connect(apiKey, language);
    } on OpenAiException catch (e) {
      // Retry without the hint if the model rejects this language code.
      if (language != null && e.message.toLowerCase().contains('language')) {
        return _connect(apiKey, null);
      }
      rethrow;
    }
  }

  static Future<TranscriptionClient> _connect(String apiKey, String? language) async {
    // Browsers can't set an Authorization header on a WebSocket, so the key
    // goes in a subprotocol. The same path works on native platforms.
    final channel = WebSocketChannel.connect(_uri, protocols: [
      'realtime',
      'openai-insecure-api-key.$apiKey',
    ]);
    try {
      await channel.ready;
    } catch (e) {
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
      onError: (_) => controller.add(_Parsed(TranscriptClosed())),
      onDone: () {
        controller.add(_Parsed(TranscriptClosed()));
        controller.close();
      },
    );
    final events = controller.stream;

    channel.sink.add(jsonEncode({
      'type': 'session.update',
      'session': {
        'type': 'transcription',
        'audio': {
          'input': {
            'format': {'type': 'audio/pcm', 'rate': 24000},
            'transcription': {
              'model': model,
              if (language != null && language.length == 2) 'language': language,
            },
            'turn_detection': null,
          },
        },
      },
    }));

    final ready = await events
        .firstWhere((e) => e.ready || e.event is TranscriptError || e.event is TranscriptClosed)
        .timeout(const Duration(seconds: 15), onTimeout: () {
      throw OpenAiException('OpenAI did not respond. Try again.');
    });
    if (!ready.ready) {
      await channel.sink.close();
      final e = ready.event;
      throw e is TranscriptError ? e.error : OpenAiException('Connection to OpenAI closed.');
    }

    return TranscriptionClient._(
      channel,
      events.where((e) => e.event != null).map((e) => e.event!),
    );
  }

  void appendAudio(Uint8List pcm) => _send({
        'type': 'input_audio_buffer.append',
        'audio': base64Encode(pcm),
      });

  void commit() => _send({'type': 'input_audio_buffer.commit'});

  void clear() => _send({'type': 'input_audio_buffer.clear'});

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
    String item() => m['item_id'] as String? ?? '';
    switch (m['type']) {
      case 'session.updated':
      case 'transcription_session.updated':
        return _Parsed.ready();
      case 'input_audio_buffer.committed':
        return _Parsed(TranscriptCommitted(item()));
      case 'conversation.item.input_audio_transcription.delta':
        return _Parsed(TranscriptDelta(item(), m['delta'] as String? ?? ''));
      case 'conversation.item.input_audio_transcription.completed':
        final usage = m['usage'] as Map<String, dynamic>?;
        final seconds = usage?['type'] == 'duration' ? (usage?['seconds'] as num?)?.toDouble() : null;
        return _Parsed(TranscriptCompleted(
          item(),
          m['transcript'] as String? ?? '',
          billedSeconds: seconds ?? 0,
        ));
      case 'conversation.item.input_audio_transcription.failed':
        final err = m['error'] as Map<String, dynamic>?;
        return _Parsed(TranscriptFailed(item(), err?['message'] as String? ?? 'Transcription failed'));
      case 'error':
        final err = m['error'] as Map<String, dynamic>? ?? const {};
        return _Parsed(TranscriptError(OpenAiException(
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

  final TranscriptionEvent? event;
  final bool ready;
}
