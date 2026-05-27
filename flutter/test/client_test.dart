import 'package:buble/buble.dart';
import 'package:test/test.dart';

import 'test_http_client.dart';

void main() {
  test('sends authorization header and default base URL', () async {
    final http = TestHttpClient([
      jsonResponse({'data': <Object?>[]}),
    ]);
    final client = BubleClient(apiKey: 'sk_test', httpClient: http);

    await client.mediaModels.list();

    expect(
      http.requests.single.url.toString(),
      'https://buble.ai/api/v1/media_models',
    );
    expect(http.requests.single.headers['Authorization'], 'Bearer sk_test');
  });

  test('reads api key and base URL from provided environment', () async {
    final http = TestHttpClient([
      jsonResponse({'data': <Object?>[]}),
    ]);
    final client = BubleClient(
      httpClient: http,
      environment: {
        'BUBLE_API_KEY': 'sk_env',
        'BUBLE_BASE_URL': 'https://unit.test',
      },
    );

    await client.mediaModels.list(mediaType: 'video');

    expect(
      http.requests.single.url.toString(),
      'https://unit.test/api/v1/media_models?media_type=video',
    );
    expect(http.requests.single.headers['Authorization'], 'Bearer sk_env');
  });

  test('rejects missing api key', () {
    expect(
      () => BubleClient(environment: const {}),
      throwsA(isA<MissingApiKeyException>()),
    );
  });
}
