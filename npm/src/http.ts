import { createReadStream, statSync } from 'node:fs';
import { basename } from 'node:path';
import type { Readable } from 'node:stream';
import { BubleAPIError, BubleTimeoutError } from './errors.js';
import type { ApiErrorBody, BubleClientOptions, FetchLike, RequestOptions } from './types/common.js';
import type { UploadFileInput, UploadFileOptions } from './types/files.js';

type QueryValue = string | number | boolean | undefined | null;
type Query = Record<string, QueryValue>;

const DEFAULT_BASE_URL = 'https://buble.ai';
const DEFAULT_TIMEOUT = 60_000;

const FORBIDDEN_GENERATION_FIELDS = new Set([
  'input',
  'options',
  'scene',
  'sub_mode_id',
  'provider',
  'mediaType',
  'media_type',
  'images',
  'image_input',
  'video_input',
  'audio_input'
]);

function normalizeBaseURL(baseURL?: string) {
  return (baseURL || DEFAULT_BASE_URL).replace(/\/+$/, '');
}

function mergeHeaders(...items: Array<HeadersInit | undefined>) {
  const headers = new Headers();
  for (const item of items) {
    if (!item) continue;
    new Headers(item).forEach((value, key) => headers.set(key, value));
  }
  return headers;
}

function appendQuery(url: URL, query?: Query) {
  if (!query) return;
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null) continue;
    url.searchParams.set(key, String(value));
  }
}

async function parseResponse(response: Response) {
  const contentType = response.headers.get('content-type') || '';
  if (response.status === 204) return undefined;
  if (contentType.includes('application/json')) return response.json();
  return response.text();
}

function createTimeoutSignal(timeout: number, signal?: AbortSignal) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeout);

  if (signal) {
    if (signal.aborted) controller.abort(signal.reason);
    signal.addEventListener('abort', () => controller.abort(signal.reason), {
      once: true
    });
  }

  return {
    signal: controller.signal,
    clear: () => clearTimeout(timer)
  };
}

function assertNoForbiddenGenerationFields(body: Record<string, unknown>) {
  const forbidden = Object.keys(body).find((key) => FORBIDDEN_GENERATION_FIELDS.has(key));
  if (forbidden) {
    throw new BubleAPIError({
      status: 400,
      code: 'unsupported_field',
      message: `Field "${forbidden}" is an internal Buble field and is not supported by the public generation API.`,
      details: { field: forbidden }
    });
  }
}

function inferContentType(filename?: string) {
  const ext = filename?.split('.').pop()?.toLowerCase();
  if (!ext) return 'application/octet-stream';
  if (ext === 'png') return 'image/png';
  if (ext === 'jpg' || ext === 'jpeg') return 'image/jpeg';
  if (ext === 'webp') return 'image/webp';
  if (ext === 'gif') return 'image/gif';
  if (ext === 'mp4') return 'video/mp4';
  if (ext === 'mov') return 'video/quicktime';
  if (ext === 'webm') return 'video/webm';
  if (ext === 'mp3') return 'audio/mpeg';
  if (ext === 'wav') return 'audio/wav';
  return 'application/octet-stream';
}

function isBlob(value: unknown): value is Blob {
  return typeof Blob !== 'undefined' && value instanceof Blob;
}

function isReadable(value: unknown): value is NodeJS.ReadableStream {
  return Boolean(value && typeof (value as any).pipe === 'function');
}

function toUint8Array(value: string) {
  return new TextEncoder().encode(value);
}

async function* fileToIterable(file: UploadFileInput): AsyncIterable<Uint8Array> {
  if (typeof file === 'string') {
    yield* createReadStream(file) as unknown as AsyncIterable<Uint8Array>;
    return;
  }

  if (file instanceof ArrayBuffer) {
    yield new Uint8Array(file);
    return;
  }

  if (file instanceof Uint8Array) {
    yield file;
    return;
  }

  if (isBlob(file)) {
    for await (const chunk of file.stream() as unknown as AsyncIterable<Uint8Array>) {
      yield chunk;
    }
    return;
  }

  if (isReadable(file)) {
    for await (const chunk of file as Readable) {
      yield typeof chunk === 'string' ? toUint8Array(chunk) : new Uint8Array(chunk);
    }
    return;
  }

  throw new TypeError('Unsupported upload file input.');
}

function fileMetadata(file: UploadFileInput, options: UploadFileOptions) {
  if (typeof file === 'string') {
    const stat = statSync(file);
    const filename = options.filename || basename(file);
    return {
      filename,
      contentType: options.contentType || inferContentType(filename),
      size: stat.size
    };
  }

  if (isBlob(file)) {
    const filename = options.filename || 'file';
    return {
      filename,
      contentType: options.contentType || file.type || inferContentType(filename),
      size: file.size
    };
  }

  if (file instanceof ArrayBuffer || file instanceof Uint8Array) {
    const filename = options.filename || 'file';
    return {
      filename,
      contentType: options.contentType || inferContentType(filename),
      size: file.byteLength
    };
  }

  return {
    filename: options.filename || 'file',
    contentType: options.contentType || inferContentType(options.filename),
    size: undefined
  };
}

function multipartBody({
  file,
  fields,
  filename,
  contentType
}: {
  file: UploadFileInput;
  fields: Record<string, string>;
  filename: string;
  contentType: string;
}) {
  const boundary = `buble-sdk-${crypto.randomUUID()}`;

  async function* body() {
    for (const [name, value] of Object.entries(fields)) {
      yield toUint8Array(`--${boundary}\r\n`);
      yield toUint8Array(`Content-Disposition: form-data; name="${name}"\r\n\r\n`);
      yield toUint8Array(`${value}\r\n`);
    }

    yield toUint8Array(`--${boundary}\r\n`);
    yield toUint8Array(
      `Content-Disposition: form-data; name="file"; filename="${filename.replace(/"/g, '\\"')}"\r\n`
    );
    yield toUint8Array(`Content-Type: ${contentType}\r\n\r\n`);
    yield* fileToIterable(file);
    yield toUint8Array(`\r\n--${boundary}--\r\n`);
  }

  return {
    boundary,
    body: body() as unknown as BodyInit
  };
}

export class BubleHTTPClient {
  readonly apiKey: string;
  readonly baseURL: string;
  readonly timeout: number;
  readonly fetch: FetchLike;
  readonly headers?: HeadersInit;

  constructor(options: BubleClientOptions = {}) {
    const apiKey = options.apiKey || process.env.BUBLE_API_KEY;
    if (!apiKey) {
      throw new Error('Missing Buble API key. Pass apiKey or set BUBLE_API_KEY.');
    }

    if (!globalThis.fetch && !options.fetch) {
      throw new Error('Buble SDK requires fetch. Use Node.js 18+ or pass a custom fetch implementation.');
    }

    this.apiKey = apiKey;
    this.baseURL = normalizeBaseURL(options.baseURL || process.env.BUBLE_BASE_URL);
    this.timeout = options.timeout ?? DEFAULT_TIMEOUT;
    this.fetch = options.fetch || globalThis.fetch.bind(globalThis);
    this.headers = options.headers;
  }

  url(path: string, query?: Query) {
    const url = new URL(`${this.baseURL}${path.startsWith('/') ? path : `/${path}`}`);
    appendQuery(url, query);
    return url;
  }

  async request<T>(
    method: string,
    path: string,
    {
      query,
      body,
      headers,
      signal,
      timeout,
      raw
    }: RequestOptions & {
      query?: Query;
      body?: unknown;
      raw?: boolean;
    } = {}
  ): Promise<T> {
    const timeoutMs = timeout ?? this.timeout;
    const timeoutSignal = createTimeoutSignal(timeoutMs, signal);
    const requestHeaders = mergeHeaders(
      {
        Authorization: `Bearer ${this.apiKey}`,
        Accept: 'application/json'
      },
      this.headers,
      headers
    );

    let requestBody: BodyInit | undefined;
    if (body !== undefined) {
      requestHeaders.set('Content-Type', 'application/json');
      requestBody = JSON.stringify(body);
    }

    try {
      const response = await this.fetch(this.url(path, query), {
        method,
        headers: requestHeaders,
        body: requestBody,
        signal: timeoutSignal.signal
      });

      if (!response.ok) {
        const parsed = (await parseResponse(response)) as ApiErrorBody | string | undefined;
        const apiError = typeof parsed === 'object' ? parsed?.error : undefined;
        throw new BubleAPIError({
          status: response.status,
          code: apiError?.code,
          message: apiError?.message || response.statusText || 'Buble API request failed.',
          details: apiError?.details,
          response
        });
      }

      return (raw ? response : await parseResponse(response)) as T;
    } catch (error) {
      if (error instanceof BubleAPIError) throw error;
      if ((error as any)?.name === 'AbortError') {
        throw new BubleTimeoutError(`Buble API request timed out after ${timeoutMs}ms.`, timeoutMs);
      }
      throw error;
    } finally {
      timeoutSignal.clear();
    }
  }

  get<T>(path: string, query?: Query, options?: RequestOptions) {
    return this.request<T>('GET', path, { ...options, query });
  }

  post<T>(path: string, body?: unknown, options?: RequestOptions) {
    return this.request<T>('POST', path, { ...options, body });
  }

  async upload<T>(file: UploadFileInput, options: UploadFileOptions = {}): Promise<T> {
    const { filename, contentType } = fileMetadata(file, options);
    const fields: Record<string, string> = {};
    const fileType = options.file_type || options.fileType;

    if (fileType) fields.file_type = fileType;
    if (options.model) fields.model = options.model;
    if (options.mode) fields.mode = options.mode;

    const multipart = multipartBody({ file, fields, filename, contentType });
    const timeoutMs = options.timeout ?? this.timeout;
    const timeoutSignal = createTimeoutSignal(timeoutMs, options.signal);
    const headers = mergeHeaders(
      {
        Authorization: `Bearer ${this.apiKey}`,
        Accept: 'application/json',
        'Content-Type': `multipart/form-data; boundary=${multipart.boundary}`
      },
      this.headers
    );

    try {
      const response = await this.fetch(this.url('/api/v1/files'), {
        method: 'POST',
        headers,
        body: multipart.body,
        signal: timeoutSignal.signal,
        duplex: 'half'
      } as RequestInit & { duplex: 'half' });

      if (!response.ok) {
        const parsed = (await parseResponse(response)) as ApiErrorBody | string | undefined;
        const apiError = typeof parsed === 'object' ? parsed?.error : undefined;
        throw new BubleAPIError({
          status: response.status,
          code: apiError?.code,
          message: apiError?.message || response.statusText || 'Buble file upload failed.',
          details: apiError?.details,
          response
        });
      }

      return (await parseResponse(response)) as T;
    } catch (error) {
      if (error instanceof BubleAPIError) throw error;
      if ((error as any)?.name === 'AbortError') {
        throw new BubleTimeoutError(`Buble file upload timed out after ${timeoutMs}ms.`, timeoutMs);
      }
      throw error;
    } finally {
      timeoutSignal.clear();
    }
  }

  assertPublicGenerationBody(body: Record<string, unknown>) {
    assertNoForbiddenGenerationFields(body);
  }
}
