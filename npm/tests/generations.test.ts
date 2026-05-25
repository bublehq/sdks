import { describe, expect, it, vi } from 'vitest';
import { Buble } from '../src/index.js';

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json' }
  });
}

describe('generations resource', () => {
  it('creates flat public generation requests', async () => {
    let body: unknown;
    const client = new Buble({
      apiKey: 'sk_test',
      baseURL: 'https://example.test',
      fetch: async (_url, init) => {
        body = JSON.parse(String(init?.body));
        return json({ data: { id: 'task_1', status: 'pending' } }, 201);
      }
    });

    const result = await client.generations.create({
      model: 'google/nano-banana',
      mode: 'text_to_image',
      prompt: 'A test image',
      aspect_ratio: '1:1'
    });

    expect(body).toEqual({
      model: 'google/nano-banana',
      mode: 'text_to_image',
      prompt: 'A test image',
      aspect_ratio: '1:1'
    });
    expect(result.data.id).toBe('task_1');
  });

  it('waits until a generation reaches a terminal status', async () => {
    vi.useFakeTimers();
    const statuses = ['pending', 'processing', 'success'];
    const client = new Buble({
      apiKey: 'sk_test',
      fetch: async () => {
        const status = statuses.shift() || 'success';
        return json({ data: { id: 'task_1', status, result: status === 'success' ? { images: [] } : null } });
      }
    });

    const promise = client.generations.wait('task_1', { interval: 10, timeout: 1000 });
    await vi.advanceTimersByTimeAsync(20);
    await expect(promise).resolves.toMatchObject({
      data: { id: 'task_1', status: 'success' }
    });
    vi.useRealTimers();
  });
});
