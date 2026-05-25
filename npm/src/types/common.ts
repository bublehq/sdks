export type FetchLike = (
  input: string | URL | Request,
  init?: RequestInit
) => Promise<Response>;

export type BubleClientOptions = {
  apiKey?: string;
  baseURL?: string;
  timeout?: number;
  fetch?: FetchLike;
  headers?: HeadersInit;
};

export type RequestOptions = {
  signal?: AbortSignal;
  timeout?: number;
  headers?: HeadersInit;
};

export type ListOptions = RequestOptions & {
  page?: number;
  limit?: number;
};

export type ApiEnvelope<T> = {
  data: T;
};

export type ApiErrorBody = {
  error?: {
    code?: string;
    message?: string;
    details?: unknown;
  };
};

export type MediaType = 'image' | 'video' | 'audio';

export type TaskStatus =
  | 'pending'
  | 'processing'
  | 'success'
  | 'failed'
  | 'canceled';

export type WaitOptions = RequestOptions & {
  interval?: number;
  timeout?: number;
  throwOnFailed?: boolean;
  throwOnCanceled?: boolean;
};

export type JsonObject = Record<string, any>;
