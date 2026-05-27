import 'dart:async';
import 'dart:convert';

import 'errors.dart';
import 'types.dart';

final class ServerSentEvent {
  const ServerSentEvent({this.event, required this.data, this.json});

  final String? event;
  final String data;
  final Object? json;
}

enum StreamProtocol { openAI, anthropic, gemini }

Stream<ServerSentEvent> parseSseStream(Stream<List<int>> bytes) async* {
  var buffer = '';
  await for (final chunk in bytes.transform(utf8.decoder)) {
    buffer += chunk;
    while (true) {
      final separator = _eventSeparator.firstMatch(buffer);
      if (separator == null) break;
      final block = buffer.substring(0, separator.start);
      buffer = buffer.substring(separator.end);
      final event = _parseSseBlock(block);
      if (event != null) yield event;
    }
  }
  final event = _parseSseBlock(buffer);
  if (event != null) yield event;
}

Stream<String> streamText(
  Stream<ServerSentEvent> events,
  StreamProtocol protocol,
) async* {
  await for (final event in events) {
    if (event.data == '[DONE]') break;
    final text = switch (protocol) {
      StreamProtocol.openAI => _textFromOpenAI(event.json),
      StreamProtocol.anthropic => _textFromAnthropic(event),
      StreamProtocol.gemini => _textFromGemini(event.json),
    };
    if (text != null && text.isNotEmpty) {
      yield text;
    }
  }
}

ServerSentEvent? _parseSseBlock(String block) {
  if (block.trim().isEmpty) return null;
  String? event;
  final dataLines = <String>[];

  for (final rawLine in const LineSplitter().convert(block)) {
    final line = rawLine.trimRight();
    if (line.isEmpty || line.startsWith(':')) continue;
    final separator = line.indexOf(':');
    final field = separator == -1 ? line : line.substring(0, separator);
    final value = separator == -1
        ? ''
        : line.substring(separator + 1).replaceFirst(RegExp(r'^ '), '');

    if (field == 'event') event = value;
    if (field == 'data') dataLines.add(value);
  }

  if (event == null && dataLines.isEmpty) return null;
  final data = dataLines.join('\n');
  return ServerSentEvent(event: event, data: data, json: _tryParseJson(data));
}

Object? _tryParseJson(String data) {
  if (data.isEmpty || data == '[DONE]') return null;
  try {
    return jsonDecode(data);
  } catch (error) {
    throw BubleStreamException(
      'Failed to parse server-sent event JSON: $error',
    );
  }
}

String? _textFromOpenAI(Object? value) {
  final map = mapOrNull(value);
  final choices = listOrNull(map?['choices']);
  final first = choices?.firstOrNull;
  final delta = mapOrNull(mapOrNull(first)?['delta']);
  return delta?['content'] as String?;
}

String? _textFromAnthropic(ServerSentEvent event) {
  if (event.event != 'content_block_delta') return null;
  final json = mapOrNull(event.json);
  final delta = mapOrNull(json?['delta']);
  return delta?['text'] as String?;
}

String? _textFromGemini(Object? value) {
  final map = mapOrNull(value);
  final candidates = listOrNull(map?['candidates']);
  final first = mapOrNull(candidates?.firstOrNull);
  final content = mapOrNull(first?['content']);
  final parts = listOrNull(content?['parts']);
  return parts
      ?.map(mapOrNull)
      .whereType<JsonMap>()
      .map((part) => part['text'])
      .whereType<String>()
      .join();
}

final _eventSeparator = RegExp(r'\r?\n\r?\n');
