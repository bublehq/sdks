import type { ApiEnvelope, MediaType } from './common.js';

export type UploadFileType = MediaType;

export type UploadFileInput =
  | string
  | Uint8Array
  | ArrayBuffer
  | Blob
  | NodeJS.ReadableStream;

export type UploadFileOptions = {
  file_type?: UploadFileType;
  fileType?: UploadFileType;
  model?: string;
  mode?: string;
  filename?: string;
  contentType?: string;
  signal?: AbortSignal;
  timeout?: number;
};

export type UploadedFile = {
  object: 'file';
  provider: string;
  url: string;
  key: string;
  file_type: UploadFileType;
  content_type: string;
  size: number;
  filename: string;
};

export type UploadedFileEnvelope = ApiEnvelope<UploadedFile>;
