import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lt/openai/text_client.dart';

void main() {
  test('reads text from Responses API output messages', () {
    final response = {
      'output': [
        {'type': 'reasoning', 'summary': []},
        {
          'type': 'message',
          'content': [
            {'type': 'output_text', 'text': 'မင်္ဂလာ'},
            {'type': 'output_text', 'text': 'ပါ'},
          ],
        },
      ],
    };
    expect(extractOutputText(response), 'မင်္ဂလာပါ');
  });

  test('prefers output_text when present', () {
    expect(extractOutputText({'output_text': 'Hello', 'output': []}), 'Hello');
  });

  test('splits a server-sent event stream into data payloads', () async {
    const raw = 'event: response.output_text.delta\n'
        'data: {"delta":"မင်္ဂ"}\n\n'
        'event: response.output_text.delta\n'
        'data: {"delta":"လာ"}\n\n'
        'data: [DONE]\n';
    final bytes = utf8.encode(raw);
    // Split mid-character so multi-byte text spans chunks.
    final chunks = Stream.fromIterable([bytes.sublist(0, 40), bytes.sublist(40)]);
    expect(await sseData(chunks).toList(), ['{"delta":"မင်္ဂ"}', '{"delta":"လာ"}', '[DONE]']);
  });
}
