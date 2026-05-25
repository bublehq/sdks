import type { ApiEnvelope, JsonObject, ListOptions, TaskStatus } from './common.js';
import type { GenerationResult } from './generations.js';

export type AppInputParameter = {
  name: string;
  type: 'string' | 'number' | 'boolean' | 'array' | string;
  values?: unknown[];
};

export type PublicApp = {
  id: string;
  input_parameters: AppInputParameter[];
};

export type AppListOptions = ListOptions;

export type PublicAppsEnvelope = ApiEnvelope<PublicApp[]>;
export type PublicAppEnvelope = ApiEnvelope<PublicApp>;

export type CreateAppGenerationRequest = JsonObject;

export type AppGenerationTask = {
  id: string;
  status: TaskStatus;
  result?: GenerationResult;
  error?: {
    code?: string;
    message: string;
  };
};

export type AppGenerationTaskEnvelope = ApiEnvelope<AppGenerationTask>;
