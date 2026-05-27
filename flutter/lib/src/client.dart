import 'package:http/http.dart' as http;

import 'apps.dart';
import 'chat.dart';
import 'files.dart';
import 'generations.dart';
import 'http_client.dart';
import 'media_models.dart';

final class BubleClient {
  BubleClient({
    String? apiKey,
    Uri? baseUrl,
    Duration timeout = const Duration(seconds: 60),
    Map<String, String> headers = const {},
    http.Client? httpClient,
    Map<String, String>? environment,
  }) : this._(
          BubleHttpClient(
            apiKey: apiKey,
            baseUrl: baseUrl,
            timeout: timeout,
            headers: headers,
            httpClient: httpClient,
            env: environment,
          ),
        );

  BubleClient.fromOptions(BubleClientOptions options)
      : this._(BubleHttpClient.fromOptions(options));

  BubleClient.fromEnvironment({
    Duration timeout = const Duration(seconds: 60),
    Map<String, String> headers = const {},
    http.Client? httpClient,
  }) : this(timeout: timeout, headers: headers, httpClient: httpClient);

  BubleClient._(BubleHttpClient http)
      : _http = http,
        mediaModels = MediaModelsResource(http),
        files = FilesResource(http),
        generations = GenerationsResource(http),
        apps = AppsResource(http),
        chat = ChatResource(http);

  final BubleHttpClient _http;
  final MediaModelsResource mediaModels;
  final FilesResource files;
  final GenerationsResource generations;
  final AppsResource apps;
  final ChatResource chat;

  void close() => _http.close();
}
