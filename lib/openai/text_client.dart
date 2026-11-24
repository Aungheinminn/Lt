import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'openai_error.dart';

/// Minimal client for the Responses API, used for translation and titles.
class TextUsage {
  const TextUsage({required this.input, required this.cached, required this.output});

  final int input;
  final int cached;
  final int output;

  static TextUsage? fromResponse(Map<String, dynamic>? body) {
    final u = body?['usage'];
    if (u is! Map) return null;
    final details = u['input_tokens_details'];
    return TextUsage(
      input: (u['input_tokens'] as num?)?.toInt() ?? 0,
      cached: details is Map ? (details['cached_tokens'] as num?)?.toInt() ?? 0 : 0,
      output: (u['output_tokens'] as num?)?.toInt() ?? 0,
    );
  }
}

class OpenAiTextClient {
  OpenAiTextClient(this._apiKey, {http.Client? client, this.onUsage})
      : _http = client ?? http.Client();

  /// Called with the billed tokens of every successful request.
  final void Function(TextUsage usage)? onUsage;

  static const model = 'gpt-5.4-mini';
  static final _uri = Uri.parse('https://api.openai.com/v1/responses');

  final String _apiKey;
  final http.Client _http;

  /// The API default is "medium", which makes the model think before every
  /// line and adds seconds of delay for no gain on short translations.
  static String _effort = 'none';

  Future<String> respond({
    required String instructions,
    required String input,
    void Function(String textSoFar)? onDelta,
  }) async {
    try {
      return await _respond(instructions, input, onDelta);
    } on OpenAiException catch (e) {
      if (_effort == 'low' || !_isEffortRejected(e)) rethrow;
      _effort = 'low';
      return _respond(instructions, input, onDelta);
    }
  }

  static bool _isEffortRejected(OpenAiException e) {
    final m = e.message.toLowerCase();
    return m.contains('reasoning') || m.contains('effort');
  }

  Future<String> _respond(
    String instructions,
    String input,
    void Function(String textSoFar)? onDelta,
  ) async {
    final req = http.Request('POST', _uri)
      ..headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({
        'model': model,
        'instructions': instructions,
        'input': input,
        'reasoning': {'effort': _effort},
        'store': false,
        'stream': true,
      });
    final res = await _http.send(req);
    if (res.statusCode != 200) {
      final err = _decode(await res.stream.toBytes())?['error'] as Map<String, dynamic>?;
      throw OpenAiException(
        err?['message'] as String? ?? 'OpenAI request failed (${res.statusCode})',
        code: err?['code'] as String?,
      );
    }

    final text = StringBuffer();
    Map<String, dynamic>? completed;
    await for (final data in sseData(res.stream)) {
      final Map<String, dynamic> event;
      try {
        event = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      switch (event['type']) {
        case 'response.output_text.delta':
          text.write(event['delta'] as String? ?? '');
          onDelta?.call(text.toString());
        case 'response.completed':
          completed = event['response'] as Map<String, dynamic>?;
        case 'response.failed' || 'response.incomplete' || 'error':
          final err = (event['response'] as Map<String, dynamic>?)?['error'] ?? event['error'] ?? event;
          throw OpenAiException(
            err is Map ? err['message'] as String? ?? 'OpenAI request failed' : 'OpenAI request failed',
            code: err is Map ? err['code'] as String? : null,
          );
      }
    }
    final usage = TextUsage.fromResponse(completed);
    if (usage != null) onUsage?.call(usage);
    final out = text.isNotEmpty ? text.toString() : extractOutputText(completed ?? const {});
    return out.trim();
  }

  static const speechModel = 'gpt-4o-mini-tts';
  static const speechVoice = 'marin';

  /// MP3 audio of [text] spoken aloud.
  Future<Uint8List> speech(String text) async {
    final res = await _http.post(
      Uri.parse('https://api.openai.com/v1/audio/speech'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': speechModel,
        'voice': speechVoice,
        'input': text,
        'response_format': 'mp3',
      }),
    );
    if (res.statusCode != 200) {
      final err = _decode(res.bodyBytes)?['error'] as Map<String, dynamic>?;
      throw OpenAiException(
        err?['message'] as String? ?? 'Speech request failed (${res.statusCode})',
        code: err?['code'] as String?,
      );
    }
    return res.bodyBytes;
  }

  void close() => _http.close();

  static Map<String, dynamic>? _decode(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

/// The `data:` payloads of a server-sent event stream.
Stream<String> sseData(Stream<List<int>> bytes) async* {
  final data = StringBuffer();
  await for (final line in const LineSplitter().bind(utf8.decoder.bind(bytes))) {
    if (line.isEmpty) {
      if (data.isNotEmpty) yield data.toString();
      data.clear();
    } else if (line.startsWith('data:')) {
      if (data.isNotEmpty) data.write('\n');
      data.write(line.substring(5).trimLeft());
    }
  }
  if (data.isNotEmpty) yield data.toString();
}

/// The REST response has no `output_text` convenience field (that's an SDK
/// helper), so collect text parts from the output messages.
String extractOutputText(Map<String, dynamic> response) {
  final direct = response['output_text'];
  if (direct is String) return direct;
  final buffer = StringBuffer();
  for (final item in (response['output'] as List? ?? const [])) {
    if (item is! Map || item['type'] != 'message') continue;
    for (final part in (item['content'] as List? ?? const [])) {
      if (part is Map && part['type'] == 'output_text') {
        buffer.write(part['text'] as String? ?? '');
      }
    }
  }
  return buffer.toString();
}

class Translator {
  Translator(this._client);

  final OpenAiTextClient _client;

  Future<String> translate({
    required String text,
    required String from,
    required String to,
    List<(String, String)> context = const [],
    void Function(String textSoFar)? onDelta,
  }) {
    final input = StringBuffer();
    if (context.isNotEmpty) {
      input.writeln('Earlier lines, for context only:');
      for (final (o, t) in context) {
        input.writeln('- $o → $t');
      }
      input.writeln();
      input.writeln('Translate this line:');
    }
    input.write(text);
    return _client.respond(
      instructions:
          'You are a live interpreter. Translate the line from $from to $to. '
          'Reply with only the translation: no quotes, notes or explanations. '
          'Keep names, numbers and the speaker\'s tone. '
          'If the line is already in $to, return it unchanged.',
      input: input.toString(),
      onDelta: onDelta,
    );
  }

  Future<String> title(List<String> lines) async {
    final t = await _client.respond(
      instructions:
          'Write a short title of 2 to 6 words for this conversation, in the '
          'same language as the conversation. Reply with only the title, no '
          'quotes or trailing punctuation.',
      input: lines.take(12).join('\n'),
    );
    return t.replaceAll(RegExp(r'^["“”]+|["“”.]+$'), '').trim();
  }
}
