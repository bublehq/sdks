import { BubleHTTPClient } from './http.js';
import { AppsResource } from './resources/apps.js';
import { ChatResource } from './resources/chat.js';
import { FilesResource } from './resources/files.js';
import { GenerationsResource } from './resources/generations.js';
import { MediaModelsResource } from './resources/media-models.js';
import type { BubleClientOptions } from './types/common.js';

export class Buble {
  readonly mediaModels: MediaModelsResource;
  readonly files: FilesResource;
  readonly generations: GenerationsResource;
  readonly apps: AppsResource;
  readonly chat: ChatResource;

  private readonly http: BubleHTTPClient;

  constructor(options: BubleClientOptions = {}) {
    this.http = new BubleHTTPClient(options);
    this.mediaModels = new MediaModelsResource(this.http);
    this.files = new FilesResource(this.http);
    this.generations = new GenerationsResource(this.http);
    this.apps = new AppsResource(this.http);
    this.chat = new ChatResource(this.http);
  }
}

export default Buble;
