import 'types.dart';

sealed class BubleException implements Exception {
  const BubleException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class MissingApiKeyException extends BubleException {
  const MissingApiKeyException()
      : super('Missing Buble API key. Pass apiKey or set BUBLE_API_KEY.');
}

final class BubleApiException extends BubleException {
  const BubleApiException({
    required this.statusCode,
    required String message,
    this.code,
    this.details,
    this.rawBody,
  }) : super(message);

  final int statusCode;
  final String? code;
  final Object? details;
  final String? rawBody;
}

final class BubleTimeoutException extends BubleException {
  const BubleTimeoutException(super.message, this.timeout);

  final Duration timeout;
}

final class UnsupportedGenerationFieldException extends BubleException {
  UnsupportedGenerationFieldException(this.field)
      : super(
          'Field "$field" is an internal Buble field and is not supported by the public generation API.',
        );

  final String field;
}

final class GenerationFailedException extends BubleException {
  GenerationFailedException(this.task)
      : super(task.error?.message ?? 'Generation failed.');

  final GenerationTask task;
}

final class GenerationCanceledException extends BubleException {
  GenerationCanceledException(this.task)
      : super('Generation ${task.id} was canceled.');

  final GenerationTask task;
}

final class AppGenerationFailedException extends BubleException {
  AppGenerationFailedException(this.task)
      : super(task.error?.message ?? 'App generation failed.');

  final AppGenerationTask task;
}

final class AppGenerationCanceledException extends BubleException {
  AppGenerationCanceledException(this.task)
      : super('App generation ${task.id} was canceled.');

  final AppGenerationTask task;
}

final class BubleStreamException extends BubleException {
  const BubleStreamException(super.message);
}
