import type { JsonObject } from './common.js';

export type ChatModel = {
  id: string;
  object: 'model';
  created?: number;
  owned_by?: string;
  name?: string;
  description?: string;
  capabilities?: {
    reasoning?: boolean;
    attachments?: boolean;
    tools?: boolean;
    [key: string]: unknown;
  };
  tags?: string[];
};

export type ChatModelList = {
  object: 'list';
  data: ChatModel[];
};

export type OpenAIChatMessage =
  | {
      role: 'system' | 'user' | 'assistant' | 'tool' | string;
      content: string | Array<JsonObject>;
      name?: string;
      tool_call_id?: string;
      [key: string]: unknown;
    }
  | JsonObject;

export type ChatCompletionCreateParams = {
  model: string;
  messages: OpenAIChatMessage[];
  stream?: boolean;
  temperature?: number;
  top_p?: number;
  stop?: string | string[];
  presence_penalty?: number;
  frequency_penalty?: number;
  response_format?: JsonObject;
  seed?: number;
  options?: JsonObject;
  extra_body?: JsonObject;
  tools?: unknown[];
  tool_choice?: unknown;
  parallel_tool_calls?: boolean;
  reasoning?: boolean;
  reasoning_effort?: string | boolean;
  max_tokens?: number;
  max_completion_tokens?: number;
  [key: string]: unknown;
};

export type ChatCompletion = JsonObject;

export type AnthropicMessageCreateParams = {
  model: string;
  messages: JsonObject[];
  system?: string;
  stream?: boolean;
  max_tokens?: number;
  temperature?: number;
  top_p?: number;
  top_k?: number;
  stop_sequences?: string[];
  options?: JsonObject;
  tools?: unknown[];
  tool_choice?: unknown;
  thinking?: boolean | JsonObject;
  reasoning?: boolean;
  [key: string]: unknown;
};

export type AnthropicMessage = JsonObject;

export type GeminiGenerateContentParams = {
  contents: JsonObject[];
  systemInstruction?: JsonObject | string;
  system_instruction?: JsonObject | string;
  generationConfig?: JsonObject;
  generation_config?: JsonObject;
  options?: JsonObject;
  tools?: unknown[];
  toolConfig?: JsonObject;
  tool_config?: JsonObject;
  reasoning?: boolean;
  thinkingConfig?: JsonObject;
  thinking_config?: JsonObject;
  [key: string]: unknown;
};

export type GeminiGenerateContentResponse = JsonObject;

export type SSEEvent = {
  event?: string;
  data: string;
  json?: unknown;
};
