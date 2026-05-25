# Buble SDKs

Official SDKs for the [Buble public API](https://buble.ai/docs).

This repository contains the SDKs for calling Buble from server-side applications. The SDKs support media model discovery, file uploads, asynchronous image and video generation, preconfigured Buble app workflows, and chat model calls through OpenAI, Anthropic Messages, and Gemini-compatible API formats.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in browser or client-side code.

## Published Packages

| Package | Install | Runtime | Source | Guide |
| --- | --- | --- | --- | --- |
| `@buble/sdk` | `npm install @buble/sdk` | Node.js 18+ | `npm/` | [npm README](npm/README.md) |
| `buble-ai` | `pip install buble-ai` | Python 3.9+ | `python/` | [Python README](python/README.md) |

## Quick Start

Set your API key:

```bash
export BUBLE_API_KEY="sk_..."
```

The generation examples below create real Buble generation tasks and may consume credits.

### JavaScript / TypeScript

Install:

```bash
npm install @buble/sdk
```

Quick start:

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

The TypeScript SDK also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

### Python

Install:

```bash
pip install buble-ai
```

Quick start:

```python
from buble_ai import Buble

client = Buble(api_key="sk_...")

task = client.generations.create(
    model="google/nano-banana",
    mode="text_to_image",
    prompt="A cinematic product photo of a matte black espresso cup",
    aspect_ratio="1:1",
    output_format="png",
)

result = client.generations.wait(task["data"]["id"])
print(result["data"]["result"]["images"][0]["url"])
```

The Python SDK also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

## Supported API Areas

The SDKs mirror the public Buble API:

| Area | Endpoints |
| --- | --- |
| Media model discovery | `GET /api/v1/media_models` |
| File uploads | `POST /api/v1/files` |
| Media generations | `POST /api/v1/generations`, `GET /api/v1/generations/{id}` |
| App workflows | `GET /api/v1/apps`, `GET /api/v1/apps/{app}`, `POST /api/v1/apps/{app}/generations`, `GET /api/v1/apps/{app}/generations/{id}` |
| Chat models | `GET /api/v1/models` |
| OpenAI-compatible chat | `POST /api/v1/chat/completions` |
| Anthropic-compatible messages | `POST /api/v1/messages` |
| Gemini-compatible chat | `POST /api/v1beta/models/{model}:generateContent`, `POST /api/v1beta/models/{model}:streamGenerateContent` |

Media and app generation tasks are asynchronous. Create a task, then poll until the task reaches `success`, `failed`, or `canceled`.

Generation request bodies use the flat public API shape. Put model-specific controls such as `duration`, `resolution`, `aspect_ratio`, `output_format`, `web_search`, and `audio` at the request root.

Do not send internal workflow fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Compatibility Model

Buble's public API is configuration-driven. New media models, modes, app inputs, and chat model capabilities can become available without an SDK release.

Use the discovery endpoints as the source of truth:

- `mediaModels.list()` / `media_models.list()` for media model keys, modes, input requirements, and parameters.
- `apps.list()` and `apps.retrieve()` for app ids and input parameters.
- `chat.models.list()` for available chat models and capabilities.

The SDKs preserve protocol-native chat response shapes. OpenAI-compatible, Anthropic-compatible, and Gemini-compatible responses are not globally wrapped or transformed.

## Common Workflows

### Discover Media Models

Use model discovery before building production requests:

```ts
const models = await buble.mediaModels.list({ media_type: 'video' });
```

```python
models = client.media_models.list(media_type="video")
```

The response contains model keys, supported modes, required inputs, and accepted parameters.

### Upload Source Media

Upload source assets before image-to-image, image-to-video, video-to-video, or audio-assisted workflows:

```ts
const uploaded = await buble.files.upload('./reference.png', {
  file_type: 'image',
  model: 'google/nano-banana',
  mode: 'image_to_image'
});
```

```python
uploaded = client.files.upload(
    "reference.png",
    file_type="image",
    model="google/nano-banana",
    mode="image_to_image",
)
```

Pass the returned URL into fields such as `image_urls`, `start_frame`, `end_frame`, `video_urls`, or `audio_urls`.

### Run App Workflows

Use apps when you want a preconfigured workflow instead of selecting a model and mode directly:

```ts
const task = await buble.apps.generations.create('video-background-remover', {
  source_video: ['https://example.com/source.mp4'],
  refine_foreground_edges: true,
  subject_is_person: true
});
```

```python
task = client.apps.generations.create(
    "video-background-remover",
    source_video=["https://example.com/source.mp4"],
    refine_foreground_edges=True,
    subject_is_person=True,
)
```

Only send input parameter names returned by `apps.list()` or `apps.retrieve()`.

### Stream Chat Output

The SDKs expose raw server-sent events and text helpers for chat streaming.

```ts
const stream = await buble.chat.completions.stream({
  model: 'openai/gpt-5.5',
  messages: [{ role: 'user', content: 'Write a short launch summary.' }]
});

for await (const text of stream.toTextStream()) {
  process.stdout.write(text);
}
```

```python
for text in client.chat.completions.stream_text(
    model="openai/gpt-5.5",
    messages=[{"role": "user", "content": "Write a short launch summary."}],
):
    print(text, end="")
```

## Repository Layout

```txt
.
├── npm/
│   ├── src/
│   ├── tests/
│   ├── examples/
│   └── docs/
└── python/
    ├── src/buble_ai/
    ├── tests/
    ├── examples/
    └── docs/
```

## Development

JavaScript / TypeScript:

```bash
cd npm
npm install
npm run typecheck
npm test
npm run build
npm run pack:check
```

Python:

```bash
cd python
python -m pip install -e ".[dev]"
pytest
python -m build
python -m twine check dist/*
```

## Live Smoke Tests

Live smoke tests require `BUBLE_API_KEY`. They call discovery and error-handling paths and are intended to avoid creating billable generation tasks.

```bash
cd npm
BUBLE_API_KEY=sk_... npm run test:live
```

```bash
cd python
BUBLE_API_KEY=sk_... python scripts/live_smoke.py
```

## License

MIT. See the package-specific license files in `npm/LICENSE` and `python/LICENSE`.
