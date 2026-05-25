import { describe, expect, it } from 'vitest';
import { Buble, BubleAPIError } from '../src/index.js';

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json' }
  });
}

describe('Buble client', () => {
  it('adds bearer auth and preserves OpenAI-style model list response', async () => {
    const calls: Array<{ url: string; init?: RequestInit }> = [];
    const client = new Buble({
      apiKey: 'sk_test',
      baseURL: 'https://example.test',
      fetch: async (url, init) => {
        calls.push({ url: String(url), init });
        return json({ object: 'list', data: [] });
      }
    });

    const result = await client.chat.models.list();

    expect(result).toEqual({ object: 'list', data: [] });
    expect(calls[0]?.url).toBe('https://example.test/api/v1/models');
    expect(new Headers(calls[0]?.init?.headers).get('authorization')).toBe('Bearer sk_test');
  });

  it('parses Buble API errors', async () => {
    const client = new Buble({
      apiKey: 'sk_test',
      baseURL: 'https://example.test',
      fetch: async () =>
        json(
          {
            error: {
              code: 'invalid_api_key',
              message: 'Invalid API key.'
            }
          },
          401
        )
    });

    await expect(client.mediaModels.list()).rejects.toMatchObject({
      name: 'BubleAPIError',
      status: 401,
      code: 'invalid_api_key',
      message: 'Invalid API key.'
    } satisfies Partial<BubleAPIError>);
  });

  it('rejects internal generation fields before sending requests', async () => {
    let called = false;
    const client = new Buble({
      apiKey: 'sk_test',
      fetch: async () => {
        called = true;
        return json({});
      }
    });

    expect(() =>
      client.generations.create({
        model: 'google/nano-banana',
        mode: 'text_to_image',
        prompt: 'test',
        options: {}
      })
    ).toThrowError(
      expect.objectContaining({
      code: 'unsupported_field'
      })
    );
    expect(called).toBe(false);
  });
});
