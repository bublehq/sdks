import 'package:buble/buble.dart';
import 'package:test/test.dart';

import 'test_http_client.dart';

void main() {
  test('creates flat generation body', () async {
    final http = TestHttpClient([
      jsonResponse({
        'data': {'id': 'task_1', 'status': 'pending'},
      }),
    ]);
    final client = BubleClient(apiKey: 'sk_test', httpClient: http);

    final task = await client.generations.create(
      CreateGenerationRequest(
        model: 'google/nano-banana',
        mode: 'text_to_image',
        prompt: 'A product image',
      ).withParam('aspect_ratio', '1:1').withParam('output_format', 'png'),
    );

    expect(task.data.id, 'task_1');
    expect(http.requests.single.jsonBody, {
      'model': 'google/nano-banana',
      'mode': 'text_to_image',
      'prompt': 'A product image',
      'aspect_ratio': '1:1',
      'output_format': 'png',
    });
  });

  test('rejects internal generation fields', () {
    expect(
      () => CreateGenerationRequest(
        model: 'google/nano-banana',
      ).withParam('options', {}),
      throwsA(isA<UnsupportedGenerationFieldException>()),
    );
  });

  test('wait raises on failed generation', () async {
    final http = TestHttpClient([
      jsonResponse({
        'data': {
          'id': 'task_1',
          'status': 'failed',
          'error': {'message': 'provider failed'},
        },
      }),
    ]);
    final client = BubleClient(apiKey: 'sk_test', httpClient: http);

    await expectLater(
      client.generations.wait('task_1'),
      throwsA(isA<GenerationFailedException>()),
    );
  });
}
