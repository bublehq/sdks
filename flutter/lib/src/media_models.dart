import 'http_client.dart';
import 'types.dart';

final class MediaModelsResource {
  const MediaModelsResource(this._http);

  final BubleHttpClient _http;

  Future<Envelope<List<MediaModel>>> list({String? mediaType}) {
    return _http.get(
      '/api/v1/media_models',
      query: {'media_type': mediaType},
      decoder: (json) => Envelope(
        data: listOfMaps(
          json['data'],
        ).map(MediaModel.fromJson).toList(growable: false),
      ),
    );
  }
}
