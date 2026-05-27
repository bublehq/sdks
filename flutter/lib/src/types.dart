typedef JsonMap = Map<String, Object?>;
typedef JsonList = List<Object?>;

final class Envelope<T> {
  const Envelope({required this.data});

  final T data;
}

enum TaskStatus {
  pending,
  processing,
  success,
  failed,
  canceled,
  unknown;

  static TaskStatus fromJson(Object? value) {
    return switch (value) {
      'pending' => TaskStatus.pending,
      'processing' => TaskStatus.processing,
      'success' => TaskStatus.success,
      'failed' => TaskStatus.failed,
      'canceled' => TaskStatus.canceled,
      _ => TaskStatus.unknown,
    };
  }

  bool get isTerminal {
    return this == TaskStatus.success ||
        this == TaskStatus.failed ||
        this == TaskStatus.canceled;
  }

  String get value => switch (this) {
        TaskStatus.pending => 'pending',
        TaskStatus.processing => 'processing',
        TaskStatus.success => 'success',
        TaskStatus.failed => 'failed',
        TaskStatus.canceled => 'canceled',
        TaskStatus.unknown => 'unknown',
      };
}

final class MediaModel {
  const MediaModel({
    required this.model,
    this.name,
    this.mediaType,
    this.operations = const [],
    this.raw = const {},
  });

  factory MediaModel.fromJson(JsonMap json) {
    return MediaModel(
      model: json['model'] as String? ?? '',
      name: json['name'] as String?,
      mediaType: json['media_type'] as String?,
      operations: listOfMaps(
        json['operations'],
      ).map(MediaModelOperation.fromJson).toList(growable: false),
      raw: json,
    );
  }

  final String model;
  final String? name;
  final String? mediaType;
  final List<MediaModelOperation> operations;
  final JsonMap raw;
}

final class MediaModelOperation {
  const MediaModelOperation({
    required this.mode,
    this.description,
    this.input,
    this.parameters = const [],
    this.raw = const {},
  });

  factory MediaModelOperation.fromJson(JsonMap json) {
    return MediaModelOperation(
      mode: json['mode'] as String? ?? '',
      description: json['description'] as String?,
      input: json['input'],
      parameters: listOfMaps(
        json['parameters'],
      ).map(MediaModelParameter.fromJson).toList(growable: false),
      raw: json,
    );
  }

  final String mode;
  final String? description;
  final Object? input;
  final List<MediaModelParameter> parameters;
  final JsonMap raw;
}

final class MediaModelParameter {
  const MediaModelParameter({
    required this.name,
    this.type,
    this.label,
    this.defaultValue,
    this.values,
    this.required,
    this.raw = const {},
  });

  factory MediaModelParameter.fromJson(JsonMap json) {
    return MediaModelParameter(
      name: json['name'] as String? ?? '',
      type: json['type'] as String?,
      label: json['label'] as String?,
      defaultValue: json['default'],
      values: listOrNull(json['values']),
      required: json['required'] as bool?,
      raw: json,
    );
  }

  final String name;
  final String? type;
  final String? label;
  final Object? defaultValue;
  final JsonList? values;
  final bool? required;
  final JsonMap raw;
}

final class UploadedFile {
  const UploadedFile({
    required this.object,
    required this.provider,
    required this.url,
    required this.key,
    required this.fileType,
    required this.contentType,
    required this.size,
    required this.filename,
    this.raw = const {},
  });

  factory UploadedFile.fromJson(JsonMap json) {
    return UploadedFile(
      object: json['object'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      url: Uri.parse(json['url'] as String? ?? ''),
      key: json['key'] as String? ?? '',
      fileType: json['file_type'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      filename: json['filename'] as String? ?? '',
      raw: json,
    );
  }

  final String object;
  final String provider;
  final Uri url;
  final String key;
  final String fileType;
  final String contentType;
  final int size;
  final String filename;
  final JsonMap raw;
}

final class MediaResultImage {
  const MediaResultImage({required this.url, this.raw = const {}});

  factory MediaResultImage.fromJson(JsonMap json) {
    return MediaResultImage(
      url: Uri.parse(json['url'] as String? ?? ''),
      raw: json,
    );
  }

  final Uri url;
  final JsonMap raw;
}

final class MediaResultVideo {
  const MediaResultVideo({
    required this.url,
    this.previewUrl,
    this.thumbnailUrl,
    this.duration,
    this.raw = const {},
  });

  factory MediaResultVideo.fromJson(JsonMap json) {
    return MediaResultVideo(
      url: Uri.parse(json['url'] as String? ?? ''),
      previewUrl: uriOrNull(json['preview_url']),
      thumbnailUrl: uriOrNull(json['thumbnail_url']),
      duration: json['duration'],
      raw: json,
    );
  }

  final Uri url;
  final Uri? previewUrl;
  final Uri? thumbnailUrl;
  final Object? duration;
  final JsonMap raw;
}

final class MediaResultAudio {
  const MediaResultAudio({
    required this.url,
    this.imageUrl,
    this.title,
    this.duration,
    this.raw = const {},
  });

  factory MediaResultAudio.fromJson(JsonMap json) {
    return MediaResultAudio(
      url: Uri.parse(json['url'] as String? ?? ''),
      imageUrl: uriOrNull(json['image_url']),
      title: json['title'] as String?,
      duration: json['duration'],
      raw: json,
    );
  }

  final Uri url;
  final Uri? imageUrl;
  final String? title;
  final Object? duration;
  final JsonMap raw;
}

final class GenerationResult {
  const GenerationResult({
    this.images = const [],
    this.videos = const [],
    this.audios = const [],
    this.raw = const {},
  });

  factory GenerationResult.fromJson(JsonMap json) {
    return GenerationResult(
      images: listOfMaps(
        json['images'],
      ).map(MediaResultImage.fromJson).toList(growable: false),
      videos: listOfMaps(
        json['videos'],
      ).map(MediaResultVideo.fromJson).toList(growable: false),
      audios: listOfMaps(
        json['audios'],
      ).map(MediaResultAudio.fromJson).toList(growable: false),
      raw: json,
    );
  }

  final List<MediaResultImage> images;
  final List<MediaResultVideo> videos;
  final List<MediaResultAudio> audios;
  final JsonMap raw;
}

final class GenerationTaskError {
  const GenerationTaskError({this.code, this.message, this.raw = const {}});

  factory GenerationTaskError.fromJson(JsonMap json) {
    return GenerationTaskError(
      code: json['code'] as String?,
      message: json['message'] as String?,
      raw: json,
    );
  }

  final String? code;
  final String? message;
  final JsonMap raw;
}

final class GenerationTask {
  const GenerationTask({
    required this.id,
    required this.status,
    this.model,
    this.mediaType,
    this.mode,
    this.costCredits,
    this.createdAt,
    this.updatedAt,
    this.result,
    this.error,
    this.raw = const {},
  });

  factory GenerationTask.fromJson(JsonMap json) {
    return GenerationTask(
      id: json['id'] as String? ?? '',
      status: TaskStatus.fromJson(json['status']),
      model: json['model'] as String?,
      mediaType: json['media_type'] as String?,
      mode: json['mode'] as String?,
      costCredits: json['cost_credits'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      result: mapOrNull(json['result']) == null
          ? null
          : GenerationResult.fromJson(mapOrNull(json['result'])!),
      error: mapOrNull(json['error']) == null
          ? null
          : GenerationTaskError.fromJson(mapOrNull(json['error'])!),
      raw: json,
    );
  }

  final String id;
  final TaskStatus status;
  final String? model;
  final String? mediaType;
  final String? mode;
  final int? costCredits;
  final String? createdAt;
  final String? updatedAt;
  final GenerationResult? result;
  final GenerationTaskError? error;
  final JsonMap raw;
}

final class PublicApp {
  const PublicApp({
    required this.id,
    this.inputParameters = const [],
    this.raw = const {},
  });

  factory PublicApp.fromJson(JsonMap json) {
    return PublicApp(
      id: json['id'] as String? ?? '',
      inputParameters: listOfMaps(
        json['input_parameters'],
      ).map(AppInputParameter.fromJson).toList(growable: false),
      raw: json,
    );
  }

  final String id;
  final List<AppInputParameter> inputParameters;
  final JsonMap raw;
}

final class AppInputParameter {
  const AppInputParameter({
    required this.name,
    required this.type,
    this.values,
    this.raw = const {},
  });

  factory AppInputParameter.fromJson(JsonMap json) {
    return AppInputParameter(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      values: listOrNull(json['values']),
      raw: json,
    );
  }

  final String name;
  final String type;
  final JsonList? values;
  final JsonMap raw;
}

final class AppGenerationTask {
  const AppGenerationTask({
    required this.id,
    required this.status,
    this.result,
    this.error,
    this.raw = const {},
  });

  factory AppGenerationTask.fromJson(JsonMap json) {
    return AppGenerationTask(
      id: json['id'] as String? ?? '',
      status: TaskStatus.fromJson(json['status']),
      result: mapOrNull(json['result']) == null
          ? null
          : GenerationResult.fromJson(mapOrNull(json['result'])!),
      error: mapOrNull(json['error']) == null
          ? null
          : GenerationTaskError.fromJson(mapOrNull(json['error'])!),
      raw: json,
    );
  }

  GenerationTask toGenerationTask() {
    return GenerationTask(
      id: id,
      status: status,
      result: result,
      error: error,
      raw: raw,
    );
  }

  final String id;
  final TaskStatus status;
  final GenerationResult? result;
  final GenerationTaskError? error;
  final JsonMap raw;
}

final class ChatModel {
  const ChatModel({
    required this.id,
    required this.object,
    this.created,
    this.ownedBy,
    this.name,
    this.description,
    this.capabilities,
    this.tags = const [],
    this.raw = const {},
  });

  factory ChatModel.fromJson(JsonMap json) {
    return ChatModel(
      id: json['id'] as String? ?? '',
      object: json['object'] as String? ?? '',
      created: json['created'] as int?,
      ownedBy: json['owned_by'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      capabilities: mapOrNull(json['capabilities']),
      tags: listOrNull(json['tags'])?.whereType<String>().toList() ?? const [],
      raw: json,
    );
  }

  final String id;
  final String object;
  final int? created;
  final String? ownedBy;
  final String? name;
  final String? description;
  final JsonMap? capabilities;
  final List<String> tags;
  final JsonMap raw;
}

final class ChatModelList {
  const ChatModelList({
    required this.object,
    required this.data,
    this.raw = const {},
  });

  factory ChatModelList.fromJson(JsonMap json) {
    return ChatModelList(
      object: json['object'] as String? ?? '',
      data: listOfMaps(
        json['data'],
      ).map(ChatModel.fromJson).toList(growable: false),
      raw: json,
    );
  }

  final String object;
  final List<ChatModel> data;
  final JsonMap raw;
}

JsonMap asJsonMap(Object? value) {
  return Map<String, Object?>.from(value as Map);
}

JsonMap? mapOrNull(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.from(value);
  }
  return null;
}

JsonList? listOrNull(Object? value) {
  if (value is List) {
    return List<Object?>.from(value);
  }
  return null;
}

List<JsonMap> listOfMaps(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .toList();
}

Uri? uriOrNull(Object? value) {
  if (value is String && value.isNotEmpty) {
    return Uri.parse(value);
  }
  return null;
}
