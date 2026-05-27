import 'package:buble/buble.dart';
import 'package:test/test.dart';

import 'test_http_client.dart';

void main() {
  test('creates OpenAI-compatible chat completion', () async {
    final http = TestHttpClient([
      jsonResponse({
        'choices': [
          {
            'message': {'content': 'Hello'},
          },
        ],
      }),
    ]);
    final client = BubleClient(apiKey: 'sk_test', httpClient: http);

    final response = await client.chat.completions.create({
      'model': 'openai/gpt-5.4',
      'messages': [
        {'role': 'user', 'content': 'Hi'},
      ],
    });

    expect(response['choices'], isA<List<Object?>>());
    expect((http.requests.single.jsonBody as Map)['stream'], false);
  });

  test('streams OpenAI text', () async {
    final http = TestHttpClient([
      textStreamResponse([
        'data: {"choices":[{"delta":{"content":"Hel"}}]}\n\n',
        'data: {"choices":[{"delta":{"content":"lo"}}]}\n\n',
        'data: [DONE]\n\n',
      ]),
    ]);
    final client = BubleClient(apiKey: 'sk_test', httpClient: http);

    final stream = await client.chat.completions.streamText({
      'model': 'openai/gpt-5.4',
      'messages': [
        {'role': 'user', 'content': 'Hi'},
      ],
    });

    expect(await stream.join(), 'Hello');
  });

  test('calls Gemini model path', () async {
    final http = TestHttpClient([
      jsonResponse({'candidates': <Object?>[]}),
    ]);
    final client = BubleClient(apiKey: 'sk_test', httpClient: http);

    await client.chat.gemini.generateContent('openai/gpt-5.4', {
      'contents': <Object?>[],
    });

    expect(
      http.requests.single.url.path,
      '/api/v1beta/models/openai/gpt-5.4:generateContent',
    );
  });
}
