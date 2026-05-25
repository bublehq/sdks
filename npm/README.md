# @buble/sdk

TypeScript SDK for the Buble public API. Use it from server-side Node.js code to create AI image and video generation tasks, run preconfigured Buble apps, upload source media, and call Buble chat models through OpenAI, Anthropic, or Gemini-compatible endpoints.

> Keep your API key on the server. Do not expose `BUBLE_API_KEY` in browser JavaScript.

## Installation

```bash
npm install @buble/sdk
```

## Quick Start

```ts
import { Buble } from '@buble/sdk';

const buble = new Buble({
  apiKey: process.env.BUBLE_API_KEY
});

const task = await buble.generations.create({
  model: 'google/nano-banana',
  mode: 'text_to_image',
  prompt: 'A cinematic product photo of a matte black espresso cup',
  aspect_ratio: '1:1',
  output_format: 'png'
});

const result = await buble.generations.wait(task.data.id);
console.log(result.data.result?.images?.[0]?.url);
```

## Configuration

```ts
const buble = new Buble({
  apiKey: process.env.BUBLE_API_KEY,
  baseURL: 'https://buble.ai',
  timeout: 60_000
});
```

The SDK also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

## Discover Media Models

```ts
const models = await buble.mediaModels.list({ media_type: 'video' });

for (const model of models.data) {
  console.log(model.model, model.operations.map((op) => op.mode));
}
```

Use `/api/v1/media_models` as the source of truth for model keys, modes, required inputs, and public parameters. New Buble models can appear without an SDK release.

## Upload Files

```ts
const uploaded = await buble.files.upload('./reference.png', {
  file_type: 'image',
  model: 'google/nano-banana',
  mode: 'image_to_image'
});

const edited = await buble.generations.create({
  model: 'google/nano-banana',
  mode: 'image_to_image',
  prompt: 'Turn this into a polished ecommerce hero image.',
  image_urls: [uploaded.data.url]
});
```

`files.upload` supports local file paths, `Blob`, `ArrayBuffer`, `Uint8Array`, and Node readable streams. Local file paths are uploaded as streaming multipart bodies.

## Video Generation

```ts
const task = await buble.generations.create({
  model: 'doubao/seedance-2.0-fast',
  mode: 'text_to_video',
  prompt: 'A slow cinematic shot of a futuristic train station at sunrise.',
  duration: '8s',
  resolution: '720p',
  aspect_ratio: '16:9'
});

const result = await buble.generations.wait(task.data.id, {
  interval: 2_000,
  timeout: 10 * 60_000
});

console.log(result.data.result?.videos?.[0]?.url);
```

Generation request bodies are flat JSON. Do not send internal Buble fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Apps

```ts
const app = await buble.apps.retrieve('video-background-remover');
console.log(app.data.input_parameters);

const task = await buble.apps.generations.create('video-background-remover', {
  source_video: ['https://example.com/source.mp4'],
  refine_foreground_edges: true,
  subject_is_person: true
});

const result = await buble.apps.generations.wait('video-background-remover', task.data.id);
console.log(result.data.result?.videos?.[0]?.url);
```

Apps are preconfigured workflows. Only send parameter names returned by `apps.list()` or `apps.retrieve()`.

## Chat

### OpenAI-Compatible

```ts
const completion = await buble.chat.completions.create({
  model: 'openai/gpt-5.5',
  messages: [{ role: 'user', content: 'Write a short launch summary.' }],
  reasoning: true,
  max_completion_tokens: 800
});

console.log(completion.choices?.[0]?.message?.content);
```

### OpenAI-Compatible Streaming

```ts
const stream = await buble.chat.completions.stream({
  model: 'openai/gpt-5.5',
  messages: [{ role: 'user', content: 'Write one sentence at a time.' }]
});

for await (const text of stream.toTextStream()) {
  process.stdout.write(text);
}
```

### Anthropic-Compatible

```ts
const message = await buble.chat.messages.create({
  model: 'openai/gpt-5.5',
  system: 'You are concise.',
  messages: [{ role: 'user', content: 'Summarize this release.' }],
  max_tokens: 800
});
```

### Gemini-Compatible

```ts
const response = await buble.chat.gemini.generateContent('openai/gpt-5.5', {
  contents: [
    {
      role: 'user',
      parts: [{ text: 'Write a short launch summary.' }]
    }
  ]
});
```

Gemini streaming uses `streamGenerateContent`, not `stream: true`:

```ts
const stream = await buble.chat.gemini.streamGenerateContent('openai/gpt-5.5', {
  contents: [{ role: 'user', parts: [{ text: 'Stream a short answer.' }] }]
});
```

## Error Handling

```ts
import { BubleAPIError, BubleGenerationError } from '@buble/sdk';

try {
  await buble.generations.create({ model: 'missing/model', mode: 'text_to_image' });
} catch (error) {
  if (error instanceof BubleAPIError) {
    console.error(error.status, error.code, error.message, error.details);
  }
}

try {
  await buble.generations.wait('task_id');
} catch (error) {
  if (error instanceof BubleGenerationError) {
    console.error(error.task);
  }
}
```

## Publishing Checklist

Before publishing:

```bash
npm run build
npm test
npm run pack:check
npm publish --provenance --access public
```

The package publishes only `dist`, `README.md`, `LICENSE`, and `docs`.
