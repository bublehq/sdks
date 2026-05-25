import { describe, expect, it } from 'vitest';
import { Buble } from '../src/index.js';

function sse(lines: string) {
  const encoder = new TextEncoder();
  return new Response(
    new ReadableStream<Uint8Array>({
      start(controller) {
        controller.enqueue(encoder.encode(lines));
        controller.close();
      }
    }),
    { headers: { 'content-type': 'text/event-stream' } }
  );
}

describe('chat resource', () => {
  it('encodes Gemini model path by segment and preserves slash model keys', async () => {
    let requestedUrl = '';
    const client = new Buble({
      apiKey: 'sk_test',
      baseURL: 'https://example.test',
      fetch: async (url) => {
        requestedUrl = String(url);
        return new Response(JSON.stringify({ candidates: [] }), {
          headers: { 'content-type': 'application/json' }
        });
      }
    });

    await client.chat.gemini.generateContent('openai/gpt-5.5', {
      contents: [{ role: 'user', parts: [{ text: 'hi' }] }]
    });

    expect(requestedUrl).toBe(
      'https://example.test/api/v1beta/models/openai/gpt-5.5:generateContent'
    );
  });

  it('parses OpenAI-compatible SSE text deltas', async () => {
    const client = new Buble({
      apiKey: 'sk_test',
      fetch: async () =>
        sse(
          [
            'data: {"choices":[{"delta":{"content":"Hel"}}]}',
            '',
            'data: {"choices":[{"delta":{"content":"lo"}}]}',
            '',
            'data: [DONE]',
            '',
            ''
          ].join('\n')
        )
    });

    const stream = await client.chat.completions.stream({
      model: 'openai/gpt-5.5',
      messages: [{ role: 'user', content: 'hi' }]
    });

    const chunks: string[] = [];
    for await (const text of stream.toTextStream()) {
      chunks.push(text);
    }

    expect(chunks.join('')).toBe('Hello');
  });
});
