import 'dart:convert';

import 'package:buble/buble.dart';
import 'package:test/test.dart';

import 'test_http_client.dart';

void main() {
  test('uploads multipart file', () async {
    final http = TestHttpClient([
      jsonResponse({
        'data': {
          'object': 'file',
          'provider': 'r2',
          'url': 'https://example.com/source.png',
          'key': 'api/image/source.png',
          'file_type': 'image',
          'content_type': 'image/png',
          'size': 3,
          'filename': 'source.png',
        },
      }),
    ]);
    final client = BubleClient(apiKey: 'sk_test', httpClient: http);

    final uploaded = await client.files.upload(
      FileUpload.fromBytes(
        [1, 2, 3],
        filename: 'source.png',
        contentType: 'image/png',
      ),
      options: const UploadOptions(
        fileType: 'image',
        model: 'google/nano-banana',
        mode: 'image_to_image',
      ),
    );

    final body = utf8.decode(http.requests.single.body, allowMalformed: true);
    expect(uploaded.data.url.toString(), 'https://example.com/source.png');
    expect(body, contains('name="file_type"'));
    expect(body, contains('image_to_image'));
    expect(body, contains('filename="source.png"'));
  });
}
