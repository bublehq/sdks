import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

final class RecordedRequest {
  const RecordedRequest({
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
  });

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final List<int> body;

  String get bodyText => utf8.decode(body);

  Object? get jsonBody => body.isEmpty ? null : jsonDecode(bodyText);
}

final class TestHttpClient extends http.BaseClient {
  TestHttpClient(this.responses);

  final List<http.StreamedResponse> responses;
  final requests = <RecordedRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await _collect(request.finalize());
    requests.add(
      RecordedRequest(
        method: request.method,
        url: request.url,
        headers: Map<String, String>.from(request.headers),
        body: body,
      ),
    );
    if (responses.isEmpty) {
      return jsonResponse({
        'error': {'message': 'not found'},
      }, statusCode: 404);
    }
    return responses.removeAt(0);
  }
}

http.StreamedResponse jsonResponse(Object value, {int statusCode = 200}) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(value))),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

http.StreamedResponse textStreamResponse(List<String> chunks) {
  return http.StreamedResponse(
    Stream.fromIterable(chunks.map(utf8.encode)),
    200,
    headers: {'content-type': 'text/event-stream'},
  );
}

Future<List<int>> _collect(Stream<List<int>> stream) async {
  final output = <int>[];
  await for (final chunk in stream) {
    output.addAll(chunk);
  }
  return output;
}
