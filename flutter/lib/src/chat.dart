import 'http_client.dart';
import 'streaming.dart' as streaming;
import 'streaming.dart' show ServerSentEvent, parseSseStream;
import 'types.dart';
import 'url_coding.dart';

typedef ChatResponse = JsonMap;

final class ChatResource {
  ChatResource(BubleHttpClient http)
      : models = ChatModelsResource(http),
        completions = ChatCompletionsResource(http),
        messages = AnthropicMessagesResource(http),
        gemini = GeminiResource(http);

  final ChatModelsResource models;
  final ChatCompletionsResource completions;
  final AnthropicMessagesResource messages;
  final GeminiResource gemini;
}

final class ChatModelsResource {
  const ChatModelsResource(this._http);

  final BubleHttpClient _http;

  Future<ChatModelList> list() {
    return _http.get('/api/v1/models', decoder: ChatModelList.fromJson);
  }
}

final class ChatCompletionsResource {
  const ChatCompletionsResource(this._http);

  final BubleHttpClient _http;

  Future<ChatResponse> create(JsonMap body) {
    return _http.post(
      '/api/v1/chat/completions',
      body: {...body, 'stream': false},
      decoder: (json) => json,
    );
  }

  Future<Stream<ServerSentEvent>> stream(JsonMap body) async {
    final response = await _http.stream(
      'POST',
      '/api/v1/chat/completions',
      body: {...body, 'stream': true},
    );
    return parseSseStream(response.stream);
  }

  Future<Stream<String>> streamText(JsonMap body) async {
    return streaming.streamText(
      await stream(body),
      streaming.StreamProtocol.openAI,
    );
  }
}

final class AnthropicMessagesResource {
  const AnthropicMessagesResource(this._http);

  final BubleHttpClient _http;

  Future<ChatResponse> create(JsonMap body) {
    return _http.post(
      '/api/v1/messages',
      body: {...body, 'stream': false},
      decoder: (json) => json,
    );
  }

  Future<Stream<ServerSentEvent>> stream(JsonMap body) async {
    final response = await _http.stream(
      'POST',
      '/api/v1/messages',
      body: {...body, 'stream': true},
    );
    return parseSseStream(response.stream);
  }

  Future<Stream<String>> streamText(JsonMap body) async {
    return streaming.streamText(
      await stream(body),
      streaming.StreamProtocol.anthropic,
    );
  }
}

final class GeminiResource {
  const GeminiResource(this._http);

  final BubleHttpClient _http;

  Future<ChatResponse> generateContent(String model, JsonMap body) {
    return _http.post(
      '/api/v1beta/models/${encodeModelPath(model)}:generateContent',
      body: body,
      decoder: (json) => json,
    );
  }

  Future<Stream<ServerSentEvent>> streamGenerateContent(
    String model,
    JsonMap body,
  ) async {
    final response = await _http.stream(
      'POST',
      '/api/v1beta/models/${encodeModelPath(model)}:streamGenerateContent',
      body: body,
    );
    return parseSseStream(response.stream);
  }

  Future<Stream<String>> streamText(String model, JsonMap body) async {
    return streaming.streamText(
      await streamGenerateContent(model, body),
      streaming.StreamProtocol.gemini,
    );
  }
}
