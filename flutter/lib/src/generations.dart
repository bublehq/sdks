import 'dart:async';

import 'errors.dart';
import 'http_client.dart';
import 'types.dart';
import 'url_coding.dart';

const _defaultWaitInterval = Duration(seconds: 2);
const _defaultWaitTimeout = Duration(minutes: 10);

final class CreateGenerationRequest {
  CreateGenerationRequest({
    required this.model,
    this.mode,
    this.prompt,
    List<String>? imageUrls,
    this.startFrame,
    this.endFrame,
    List<String>? videoUrls,
    List<String>? audioUrls,
    this.isPublic,
    this.copyProtected,
    Map<String, Object?>? parameters,
  })  : imageUrls = imageUrls ?? const [],
        videoUrls = videoUrls ?? const [],
        audioUrls = audioUrls ?? const [],
        parameters = parameters ?? const {};

  final String model;
  final String? mode;
  final String? prompt;
  final List<String> imageUrls;
  final String? startFrame;
  final String? endFrame;
  final List<String> videoUrls;
  final List<String> audioUrls;
  final bool? isPublic;
  final bool? copyProtected;
  final Map<String, Object?> parameters;

  CreateGenerationRequest withParam(String key, Object? value) {
    assertSupportedGenerationField(key);
    return copyWith(parameters: {...parameters, key: value});
  }

  CreateGenerationRequest withParams(Map<String, Object?> values) {
    for (final key in values.keys) {
      assertSupportedGenerationField(key);
    }
    return copyWith(parameters: {...parameters, ...values});
  }

  CreateGenerationRequest copyWith({
    String? model,
    String? mode,
    String? prompt,
    List<String>? imageUrls,
    String? startFrame,
    String? endFrame,
    List<String>? videoUrls,
    List<String>? audioUrls,
    bool? isPublic,
    bool? copyProtected,
    Map<String, Object?>? parameters,
  }) {
    return CreateGenerationRequest(
      model: model ?? this.model,
      mode: mode ?? this.mode,
      prompt: prompt ?? this.prompt,
      imageUrls: imageUrls ?? this.imageUrls,
      startFrame: startFrame ?? this.startFrame,
      endFrame: endFrame ?? this.endFrame,
      videoUrls: videoUrls ?? this.videoUrls,
      audioUrls: audioUrls ?? this.audioUrls,
      isPublic: isPublic ?? this.isPublic,
      copyProtected: copyProtected ?? this.copyProtected,
      parameters: parameters ?? this.parameters,
    );
  }

  JsonMap toJson() {
    final body = <String, Object?>{
      'model': model,
      if (mode != null && mode!.isNotEmpty) 'mode': mode,
      if (prompt != null && prompt!.isNotEmpty) 'prompt': prompt,
      if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
      if (startFrame != null && startFrame!.isNotEmpty)
        'start_frame': startFrame,
      if (endFrame != null && endFrame!.isNotEmpty) 'end_frame': endFrame,
      if (videoUrls.isNotEmpty) 'video_urls': videoUrls,
      if (audioUrls.isNotEmpty) 'audio_urls': audioUrls,
      if (isPublic != null) 'is_public': isPublic,
      if (copyProtected != null) 'copy_protected': copyProtected,
      ...parameters,
    };
    for (final key in body.keys) {
      assertSupportedGenerationField(key);
    }
    return body;
  }
}

final class WaitOptions {
  const WaitOptions({
    this.interval = _defaultWaitInterval,
    this.timeout = _defaultWaitTimeout,
    this.throwOnFailed = true,
    this.throwOnCanceled = true,
  });

  final Duration interval;
  final Duration timeout;
  final bool throwOnFailed;
  final bool throwOnCanceled;
}

final class GenerationsResource {
  const GenerationsResource(this._http);

  final BubleHttpClient _http;

  Future<Envelope<GenerationTask>> create(CreateGenerationRequest request) {
    return _http.post(
      '/api/v1/generations',
      body: request.toJson(),
      decoder: (json) =>
          Envelope(data: GenerationTask.fromJson(asJsonMap(json['data']))),
    );
  }

  Future<Envelope<GenerationTask>> retrieve(String id) {
    return _http.get(
      '/api/v1/generations/${encodePathSegment(id)}',
      decoder: (json) =>
          Envelope(data: GenerationTask.fromJson(asJsonMap(json['data']))),
    );
  }

  Future<Envelope<GenerationTask>> wait(
    String id, {
    WaitOptions options = const WaitOptions(),
  }) async {
    final deadline = DateTime.now().add(options.timeout);
    while (true) {
      final envelope = await retrieve(id);
      final task = envelope.data;
      if (task.status.isTerminal) {
        if (task.status == TaskStatus.failed && options.throwOnFailed) {
          throw GenerationFailedException(task);
        }
        if (task.status == TaskStatus.canceled && options.throwOnCanceled) {
          throw GenerationCanceledException(task);
        }
        return envelope;
      }

      if (DateTime.now().isAfter(deadline)) {
        throw BubleTimeoutException(
          'Generation $id did not finish within ${options.timeout}.',
          options.timeout,
        );
      }
      await Future<void>.delayed(options.interval);
    }
  }
}

void assertSupportedGenerationField(String field) {
  if (_forbiddenGenerationFields.contains(field)) {
    throw UnsupportedGenerationFieldException(field);
  }
}

const _forbiddenGenerationFields = {
  'input',
  'options',
  'scene',
  'sub_mode_id',
  'subModeId',
  'provider',
  'mediaType',
  'media_type',
  'images',
  'image_input',
  'video_input',
  'audio_input',
};
