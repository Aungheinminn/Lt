import 'dart:convert';

import 'package:http/http.dart' as http;

import 'openai_error.dart';

/// Minimal client for the Responses API, used for translation and titles.
class OpenAiTextClient {
  OpenAiTextClient(this._apiKey, {http.Client? client})
      : _http = client ?? http.Client();

  static const model = 'gpt-5.4-mini';
  static final _uri = Uri.parse('https://api.openai.com/v1/responses');

  final String _apiKey;
  final http.Client _http;

  Future<String> respond({required String instructions, required String input}) async {
    final res = await _http.post(
      _uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'instructions': instructions,
        'input': input,
        'store': false,
      }),
    );
    final body = _decode(res.bodyBytes);
    if (res.statusCode != 200) {
      final err = body?['error'] as Map<String, dynamic>?;
      throw OpenAiException(
        err?['message'] as String? ?? 'OpenAI request failed (${res.statusCode})',
        code: err?['code'] as String?,
      );
    }
    return extractOutputText(body ?? const {}).trim();
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
