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
}
