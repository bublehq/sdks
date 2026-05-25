import type { BubleHTTPClient } from '../http.js';
import type { ListMediaModelsOptions, MediaModelsEnvelope } from '../types/media.js';

export class MediaModelsResource {
  private readonly http: BubleHTTPClient;

  constructor(http: BubleHTTPClient) {
    this.http = http;
  }

  list(options: ListMediaModelsOptions = {}) {
    const { media_type, ...requestOptions } = options;
    return this.http.get<MediaModelsEnvelope>(
      '/api/v1/media_models',
      { media_type },
      requestOptions
    );
  }
}
