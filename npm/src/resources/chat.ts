import type { BubleHTTPClient } from '../http.js';
import { BubleStream, parseSSEStream } from '../stream.js';
import type { RequestOptions } from '../types/common.js';
import type {
  AnthropicMessage,
  AnthropicMessageCreateParams,
  ChatCompletion,
  ChatCompletionCreateParams,
  ChatModelList,
  GeminiGenerateContentParams,
  GeminiGenerateContentResponse
} from '../types/chat.js';

function encodeModelPath(model: string) {
  return model.split('/').map(encodeURIComponent).join('/');
}

function eventStreamHeaders(headers?: HeadersInit) {
  const merged = new Headers(headers);
  merged.set('Accept', 'text/event-stream');
  return merged;
}

class ChatModelsResource {
  private readonly http: BubleHTTPClient;

  constructor(http: BubleHTTPClient) {
    this.http = http;
  }

  list(options?: RequestOptions) {
    return this.http.get<ChatModelList>('/api/v1/models', undefined, options);
  }
}

class ChatCompletionsResource {
  private readonly http: BubleHTTPClient;

  constructor(http: BubleHTTPClient) {
    this.http = http;
  }

  create(body: ChatCompletionCreateParams, options?: RequestOptions) {
    return this.http.post<ChatCompletion>(
      '/api/v1/chat/completions',
      { ...body, stream: false },
      options
    );
  }

  async stream(body: ChatCompletionCreateParams, options?: RequestOptions) {
    const response = await this.http.request<Response>('POST', '/api/v1/chat/completions', {
      ...options,
      body: { ...body, stream: true },
      headers: eventStreamHeaders(options?.headers),
      raw: true
    });
    return new BubleStream(parseSSEStream(response.body), 'openai');
  }
}

class AnthropicMessagesResource {
  private readonly http: BubleHTTPClient;

  constructor(http: BubleHTTPClient) {
    this.http = http;
  }

  create(body: AnthropicMessageCreateParams, options?: RequestOptions) {
    return this.http.post<AnthropicMessage>(
      '/api/v1/messages',
      { ...body, stream: false },
      options
    );
  }

  async stream(body: AnthropicMessageCreateParams, options?: RequestOptions) {
    const response = await this.http.request<Response>('POST', '/api/v1/messages', {
      ...options,
      body: { ...body, stream: true },
      headers: eventStreamHeaders(options?.headers),
      raw: true
    });
    return new BubleStream(parseSSEStream(response.body), 'anthropic');
  }
}

class GeminiResource {
  private readonly http: BubleHTTPClient;

  constructor(http: BubleHTTPClient) {
    this.http = http;
  }

  generateContent(model: string, body: GeminiGenerateContentParams, options?: RequestOptions) {
    return this.http.post<GeminiGenerateContentResponse>(
      `/api/v1beta/models/${encodeModelPath(model)}:generateContent`,
      body,
      options
    );
  }

  async streamGenerateContent(
    model: string,
    body: GeminiGenerateContentParams,
    options?: RequestOptions
  ) {
    const response = await this.http.request<Response>(
      'POST',
      `/api/v1beta/models/${encodeModelPath(model)}:streamGenerateContent`,
      {
        ...options,
        body,
        headers: eventStreamHeaders(options?.headers),
        raw: true
      }
    );
    return new BubleStream(parseSSEStream(response.body), 'gemini');
  }
}

export class ChatResource {
  readonly models: ChatModelsResource;
  readonly completions: ChatCompletionsResource;
  readonly messages: AnthropicMessagesResource;
  readonly gemini: GeminiResource;

  constructor(http: BubleHTTPClient) {
    this.models = new ChatModelsResource(http);
    this.completions = new ChatCompletionsResource(http);
    this.messages = new AnthropicMessagesResource(http);
    this.gemini = new GeminiResource(http);
  }
}
