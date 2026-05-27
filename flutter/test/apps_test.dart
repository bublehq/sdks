import 'package:buble/buble.dart';
import 'package:test/test.dart';

import 'test_http_client.dart';

void main() {
  test('lists apps with query', () async {
    final http = TestHttpClient([
      jsonResponse({
        'data': [
          {
            'id': 'video-background-remover',
            'input_parameters': [
              {'name': 'source_video', 'type': 'array'},
            ],
          },
        ],
      }),
    ]);
    final client = BubleClient(apiKey: 'sk_test', httpClient: http);

    final apps = await client.apps.list(
      options: const ListAppsOptions(limit: 20),
    );

    expect(apps.data.single.id, 'video-background-remover');
    expect(http.requests.single.url.query, 'limit=20');
  });

  test('creates and waits for app generation', () async {
    final http = TestHttpClient([
      jsonResponse({
        'data': {'id': 'task_1', 'status': 'pending'},
      }),
      jsonResponse({
        'data': {
          'id': 'task_1',
          'status': 'success',
          'result': {
            'videos': [
              {'url': 'https://example.com/video.mp4'},
            ],
          },
        },
      }),
    ]);
    final client = BubleClient(apiKey: 'sk_test', httpClient: http);

    final task = await client.apps.generations.create(
      'video-background-remover',
      {
        'source_video': ['https://example.com/source.mp4'],
      },
    );
    final result = await client.apps.generations.wait(
      'video-background-remover',
      task.data.id,
    );

    expect(
      result.data.result?.videos.single.url.toString(),
      'https://example.com/video.mp4',
    );
    expect(
      http.requests.first.url.path,
      '/api/v1/apps/video-background-remover/generations',
    );
    expect(
      http.requests.last.url.path,
      '/api/v1/apps/video-background-remover/generations/task_1',
    );
  });
}
