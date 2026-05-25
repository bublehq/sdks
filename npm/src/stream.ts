import type { SSEEvent } from './types/chat.js';

function tryParseJson(data: string) {
  if (!data || data === '[DONE]') return undefined;
  try {
    return JSON.parse(data);
  } catch {
    return undefined;
  }
}

function parseSSEBlock(block: string): SSEEvent | undefined {
  let event: string | undefined;
  const dataLines: string[] = [];

  for (const rawLine of block.split(/\r?\n/)) {
    const line = rawLine.trimEnd();
    if (!line || line.startsWith(':')) continue;
    const separator = line.indexOf(':');
    const field = separator === -1 ? line : line.slice(0, separator);
    const value = separator === -1 ? '' : line.slice(separator + 1).replace(/^ /, '');

    if (field === 'event') event = value;
    if (field === 'data') dataLines.push(value);
  }

  if (!event && dataLines.length === 0) return undefined;

  const data = dataLines.join('\n');
  return { event, data, json: tryParseJson(data) };
}

export async function* parseSSEStream(
  body: ReadableStream<Uint8Array> | null
): AsyncIterable<SSEEvent> {
  if (!body) return;

  const reader = body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });

      while (true) {
        const match = buffer.match(/\r?\n\r?\n/);
        if (!match?.index && match?.index !== 0) break;

        const block = buffer.slice(0, match.index);
        buffer = buffer.slice(match.index + match[0].length);
        const event = parseSSEBlock(block);
        if (event) yield event;
      }
    }

    buffer += decoder.decode();
    const event = parseSSEBlock(buffer);
    if (event) yield event;
  } finally {
    reader.releaseLock();
  }
}

function textFromOpenAIChunk(value: unknown) {
  const chunk = value as any;
  return chunk?.choices?.[0]?.delta?.content;
}

function textFromAnthropicEvent(value: SSEEvent) {
  const json = value.json as any;
  if (value.event === 'content_block_delta') {
    return json?.delta?.text;
  }
  return undefined;
}

function textFromGeminiChunk(value: unknown) {
  const chunk = value as any;
  return chunk?.candidates?.[0]?.content?.parts
    ?.map((part: any) => part?.text)
    .filter(Boolean)
    .join('');
}

export async function* streamText(
  events: AsyncIterable<SSEEvent>,
  protocol: 'openai' | 'anthropic' | 'gemini'
): AsyncIterable<string> {
  for await (const event of events) {
    if (event.data === '[DONE]') break;
    const text =
      protocol === 'openai'
        ? textFromOpenAIChunk(event.json)
        : protocol === 'anthropic'
          ? textFromAnthropicEvent(event)
          : textFromGeminiChunk(event.json);
    if (typeof text === 'string' && text.length > 0) {
      yield text;
    }
  }
}

export class BubleStream implements AsyncIterable<SSEEvent> {
  readonly events: AsyncIterable<SSEEvent>;
  readonly protocol: 'openai' | 'anthropic' | 'gemini';

  constructor(
    events: AsyncIterable<SSEEvent>,
    protocol: 'openai' | 'anthropic' | 'gemini'
  ) {
    this.events = events;
    this.protocol = protocol;
  }

  [Symbol.asyncIterator]() {
    return this.events[Symbol.asyncIterator]();
  }

  toTextStream() {
    return streamText(this.events, this.protocol);
  }
}
