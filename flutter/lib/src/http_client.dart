import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'environment_stub.dart' if (dart.library.io) 'environment_io.dart'
    as environment;
import 'errors.dart';
import 'types.dart';

const _defaultBaseUrl = 'https://buble.ai';
const _defaultTimeout = Duration(seconds: 60);

typedef JsonDecoder<T> = T Function(JsonMap json);

final class BubleClientOptions {
  const BubleClientOptions({
    this.apiKey,
    this.baseUrl,
    this.timeout = _defaultTimeout,
    this.headers = const {},
    this.httpClient,
  });

  final String? apiKey;
  final Uri? baseUrl;
  final Duration timeout;
  final Map<String, String> headers;
  final http.Client? httpClient;
}

final class BubleHttpClient {
  BubleHttpClient({
    String? apiKey,
    Uri? baseUrl,
    Duration timeout = _defaultTimeout,
    Map<String, String> headers = const {},
    http.Client? httpClient,
    Map<String, String>? env,
  })  : _apiKey = _resolveApiKey(apiKey, env),
        _baseUrl = _resolveBaseUrl(baseUrl, env),
        _timeout = timeout,
        _headers = headers,
        _client = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  BubleHttpClient.fromOptions(BubleClientOptions options)
      : this(
          apiKey: options.apiKey,
          baseUrl: options.baseUrl,
          timeout: options.timeout,
          headers: options.headers,
          httpClient: options.httpClient,
        );

  final String _apiKey;
  final Uri _baseUrl;
  final Duration _timeout;
  final Map<String, String> _headers;
  final http.Client _client;
  final bool _ownsClient;

  Uri url(String path, [Map<String, Object?>? query]) {
    final base = _baseUrl.toString().replaceFirst(RegExp(r'/+$'), '');
    final full = Uri.parse('$base${path.startsWith('/') ? '' : '/'}$path');
    final queryParameters = <String, String>{...full.queryParameters};
    if (query != null) {
      for (final entry in query.entries) {
        final value = entry.value;
        if (value == null) continue;
        queryParameters[entry.key] = value.toString();
      }
    }
    return full.replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  Future<T> get<T>(
    String path, {
    Map<String, Object?>? query,
    JsonDecoder<T>? decoder,
    Duration? timeout,
    Map<String, String>? headers,
  }) {
    return request(
      'GET',
      path,
      query: query,
      decoder: decoder,
      timeout: timeout,
      headers: headers,
    );
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    JsonDecoder<T>? decoder,
    Duration? timeout,
    Map<String, String>? headers,
  }) {
    return request(
      'POST',
      path,
      body: body,
      decoder: decoder,
      timeout: timeout,
      headers: headers,
    );
  }

  Future<T> request<T>(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    JsonDecoder<T>? decoder,
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    final request = http.Request(method, url(path, query));
    request.headers.addAll(_requestHeaders(headers));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final streamed = await _send(request, timeout ?? _timeout);
    final response = await http.Response.fromStream(streamed);
    return _decodeResponse(response, decoder);
  }

  Future<http.StreamedResponse> stream(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final request = http.Request(method, url(path));
    request.headers.addAll(_requestHeaders(headers));
    request.headers['Accept'] = 'text/event-stream';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final response = await _send(request, timeout ?? _timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final bodyText = await response.stream.bytesToString();
      throw _apiException(response.statusCode, bodyText);
    }
    return response;
  }

  Future<T> sendMultipart<T>(
    http.MultipartRequest request, {
    JsonDecoder<T>? decoder,
    Duration? timeout,
  }) async {
    request.headers.addAll(_requestHeaders());
    final streamed = await _send(request, timeout ?? _timeout);
    final response = await http.Response.fromStream(streamed);
    return _decodeResponse(response, decoder);
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Map<String, String> _requestHeaders([Map<String, String>? headers]) {
    return {
      ..._headers,
      if (headers != null) ...headers,
      'Authorization': 'Bearer $_apiKey',
      'User-Agent': 'buble-dart/0.1.0',
    };
  }

  Future<http.StreamedResponse> _send(
    http.BaseRequest request,
    Duration timeout,
  ) async {
    try {
      return await _client.send(request).timeout(timeout);
    } on TimeoutException {
      throw BubleTimeoutException('Buble API request timed out.', timeout);
    }
  }

  T _decodeResponse<T>(http.Response response, JsonDecoder<T>? decoder) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiException(response.statusCode, response.body);
    }
    if (T == String) {
      return response.body as T;
    }
    if (response.body.isEmpty) {
      return null as T;
    }

    final decoded = jsonDecode(response.body);
    if (decoder == null) {
      return decoded as T;
    }
    return decoder(asJsonMap(decoded));
  }

  BubleApiException _apiException(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      final map = decoded is Map ? Map<String, Object?>.from(decoded) : null;
      final error = mapOrNull(map?['error']) ?? map;
      return BubleApiException(
        statusCode: statusCode,
        code: error?['code'] as String?,
        message: error?['message'] as String? ?? 'Buble API request failed.',
        details: error?['details'],
        rawBody: body,
      );
    } catch (_) {
      return BubleApiException(
        statusCode: statusCode,
        message: body.isEmpty ? 'Buble API request failed.' : body,
        rawBody: body,
      );
    }
  }
}

String _resolveApiKey(String? value, Map<String, String>? env) {
  final resolved = firstPresent(value, _env(env)['BUBLE_API_KEY']);
  if (resolved == null) {
    throw const MissingApiKeyException();
  }
  return resolved;
}

Uri _resolveBaseUrl(Uri? value, Map<String, String>? env) {
  if (value != null) return value;
  return Uri.parse(firstPresent(_env(env)['BUBLE_BASE_URL'], _defaultBaseUrl)!);
}

Map<String, String> _env(Map<String, String>? env) {
  return env ?? environment.currentEnvironment();
}

String? firstPresent(String? first, String? second) {
  for (final value in [first, second]) {
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}
