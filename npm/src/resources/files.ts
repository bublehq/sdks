import type { BubleHTTPClient } from '../http.js';
import type { UploadedFileEnvelope, UploadFileInput, UploadFileOptions } from '../types/files.js';

export class FilesResource {
  private readonly http: BubleHTTPClient;

  constructor(http: BubleHTTPClient) {
    this.http = http;
  }

  upload(file: UploadFileInput, options: UploadFileOptions = {}) {
    return this.http.upload<UploadedFileEnvelope>(file, options);
  }
}
