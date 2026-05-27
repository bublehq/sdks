import 'errors.dart';
import 'generations.dart';
import 'http_client.dart';
import 'types.dart';
import 'url_coding.dart';

final class ListAppsOptions {
  const ListAppsOptions({this.page, this.limit});

  final int? page;
  final int? limit;

  Map<String, Object?> toQuery() {
    return {'page': page, 'limit': limit};
  }
}

final class AppsResource {
  AppsResource(this._http) : generations = AppGenerationsResource(_http);

  final BubleHttpClient _http;
  final AppGenerationsResource generations;

  Future<Envelope<List<PublicApp>>> list({
    ListAppsOptions options = const ListAppsOptions(),
  }) {
    return _http.get(
      '/api/v1/apps',
      query: options.toQuery(),
      decoder: (json) => Envelope(
        data: listOfMaps(
          json['data'],
        ).map(PublicApp.fromJson).toList(growable: false),
      ),
    );
  }

  Future<Envelope<PublicApp>> retrieve(String app) {
    return _http.get(
      '/api/v1/apps/${encodePathSegment(app)}',
      decoder: (json) =>
          Envelope(data: PublicApp.fromJson(asJsonMap(json['data']))),
    );
  }
}

final class AppGenerationsResource {
  const AppGenerationsResource(this._http);

  final BubleHttpClient _http;

  Future<Envelope<AppGenerationTask>> create(String app, JsonMap body) {
    return _http.post(
      '/api/v1/apps/${encodePathSegment(app)}/generations',
      body: body,
      decoder: (json) =>
          Envelope(data: AppGenerationTask.fromJson(asJsonMap(json['data']))),
    );
  }

  Future<Envelope<AppGenerationTask>> retrieve(String app, String id) {
    return _http.get(
      '/api/v1/apps/${encodePathSegment(app)}/generations/${encodePathSegment(id)}',
      decoder: (json) =>
          Envelope(data: AppGenerationTask.fromJson(asJsonMap(json['data']))),
    );
  }

  Future<Envelope<AppGenerationTask>> wait(
    String app,
    String id, {
    WaitOptions options = const WaitOptions(),
  }) async {
    final deadline = DateTime.now().add(options.timeout);
    while (true) {
      final envelope = await retrieve(app, id);
      final task = envelope.data;
      if (task.status.isTerminal) {
        if (task.status == TaskStatus.failed && options.throwOnFailed) {
          throw AppGenerationFailedException(task);
        }
        if (task.status == TaskStatus.canceled && options.throwOnCanceled) {
          throw AppGenerationCanceledException(task);
        }
        return envelope;
      }

      if (DateTime.now().isAfter(deadline)) {
        throw BubleTimeoutException(
          'App generation $id did not finish within ${options.timeout}.',
          options.timeout,
        );
      }
      await Future<void>.delayed(options.interval);
    }
  }
}
