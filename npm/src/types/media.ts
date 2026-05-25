import type { ApiEnvelope, MediaType } from './common.js';

export type MediaModelParameter = {
  name: string;
  type?: string;
  label?: string;
  default?: unknown;
  values?: unknown[];
  min?: number;
  max?: number;
  step?: number;
  required?: boolean;
};

export type MediaModelOperation = {
  mode: string;
  input?: Record<string, unknown>;
  parameters?: MediaModelParameter[];
};

export type MediaModel = {
  model: string;
  name?: string;
  media_type: MediaType | string;
  operations: MediaModelOperation[];
};

export type ListMediaModelsOptions = {
  media_type?: MediaType;
  signal?: AbortSignal;
  timeout?: number;
};

export type MediaModelsEnvelope = ApiEnvelope<MediaModel[]>;
