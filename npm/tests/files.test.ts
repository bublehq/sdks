import { describe, expect, it } from 'vitest';
import { Buble } from '../src/index.js';

describe('files resource', () => {
  it('sends multipart upload with metadata fields', async () => {
    let contentType = '';
    let bodyText = '';
    const client = new Buble({
      apiKey: 'sk_test',
      baseURL: 'https://example.test',
      fetch: async (_url, init) => {
        contentType = new Headers(init?.headers).get('content-type') || '';
        const chunks: Uint8Array[] = [];
        for await (const chunk of init?.body as unknown as AsyncIterable<Uint8Array>) {
          chunks.push(chunk);
        }
        bodyText = Buffer.concat(chunks).toString('utf8');
        return new Response(
          JSON.stringify({
            data: {
              object: 'file',
              provider: 'r2',
              url: 'https://cdn.example/file.png',
              key: 'api/image/file.png',
              file_type: 'image',
              content_type: 'image/png',
              size: 4,
              filename: 'file.png'
            }
          }),
          { status: 201, headers: { 'content-type': 'application/json' } }
        );
      }
    });

    const result = await client.files.upload(new TextEncoder().encode('test'), {
      file_type: 'image',
      filename: 'file.png',
      contentType: 'image/png',
      model: 'google/nano-banana',
      mode: 'image_to_image'
    });

    expect(contentType).toContain('multipart/form-data; boundary=');
    expect(bodyText).toContain('name="file_type"');
    expect(bodyText).toContain('image');
    expect(bodyText).toContain('name="model"');
    expect(bodyText).toContain('google/nano-banana');
    expect(bodyText).toContain('filename="file.png"');
    expect(result.data.url).toBe('https://cdn.example/file.png');
  });
});
