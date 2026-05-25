import type { ApiEnvelope, JsonObject, MediaType, TaskStatus } from './common.js';

export type GenerationMode =
  | 'text_to_image'
  | 'image_to_image'
  | 'text_to_video'
  | 'reference_to_video'
  | 'frames_to_video'
  | 'video_to_video'
  | 'video_edit'
  | 'video_extension'
  | string;

export type CreateGenerationRequest = {
  model: string;
  mode?: GenerationMode;
  prompt?: string;
  image_urls?: string[];
  start_frame?: string;
  end_frame?: string;
  video_urls?: string[];
  audio_urls?: string[];
  is_public?: boolean;
  copy_protected?: boolean;
} & JsonObject;

export type MediaResultImage = {
  url: string;
};

export type MediaResultVideo = {
  url: string;
  preview_url?: string;
  thumbnail_url?: string;
  duration?: number | string;
};

export type MediaResultAudio = {
  url: string;
  image_url?: string;
  title?: string;
  duration?: number | string;
};

export type GenerationResult = {
  images?: MediaResultImage[];
  videos?: MediaResultVideo[];
  audios?: MediaResultAudio[];
};

export type GenerationError = {
  code?: string;
  message: string;
};

export type GenerationTask = {
  id: string;
  status: TaskStatus;
  model?: string;
  media_type?: MediaType | string;
  mode?: string;
  cost_credits?: number;
  created_at?: string | Date;
  updated_at?: string | Date;
  result?: GenerationResult | null;
  error?: GenerationError;
};

export type GenerationTaskEnvelope = ApiEnvelope<GenerationTask>;
