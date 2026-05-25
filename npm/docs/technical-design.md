# @buble/sdk Technical Design

## Purpose

`@buble/sdk` is a server-side TypeScript SDK for the Buble public API. Its job is to package the stable public API contract into a convenient Node.js client without hardcoding every model, app, or provider-specific detail.

Buble's public API is configuration-driven. Media models, apps, parameters, pricing, modes, and chat capabilities can change through backend configuration. The SDK therefore treats discovery endpoints as the source of truth:

- `/api/v1/media_models` for media model capabilities.
- `/api/v1/apps` and `/api/v1/apps/{app}` for app workflow inputs.
- `/api/v1/models` for chat model availability.

## Non-Goals

- The SDK does not expose internal model config fields.
- The SDK does not hardcode all current model parameters as required types.
- The SDK does not run in browsers by default because API keys must remain server-side.
- The SDK does not replace polling with webhooks because the current public API has no webhook contract.

## Package Layout

```txt
npm/
  src/
    client.ts
    http.ts
    errors.ts
    stream.ts
    resources/
      media-models.ts
      files.ts
      generations.ts
      apps.ts
      chat.ts
    types/
      common.ts
      media.ts
      files.ts
      generations.ts
      apps.ts
      chat.ts
```

The package is independent from the Next.js app. It has its own `package.json`, TypeScript config, tests, examples, README, and technical design document.

## Runtime and Publishing

The SDK targets Node.js 18 or newer and uses the platform `fetch` API. It ships both ESM and CommonJS entry points:

- ESM: `dist/esm/index.js`
- CJS: `dist/cjs/index.js`
- Types: `dist/esm/index.d.ts`

`package.json` uses `exports` to define the public package surface. `files` limits npm tarball contents to the build output and documentation. `publishConfig` sets public access and provenance support for npm publishing.

## Client Construction

```ts
new Buble({
  apiKey,
  baseURL,
  timeout,
  fetch,
  headers
});
```

`apiKey` defaults to `process.env.BUBLE_API_KEY`. `baseURL` defaults to `https://buble.ai`, or `process.env.BUBLE_BASE_URL` when present. A custom `fetch` can be injected for tests, proxies, or specialized server runtimes.

## HTTP Layer

The HTTP layer owns:

- Bearer authentication.
- Base URL and query construction.
- JSON request serialization.
- JSON/text response parsing.
- Public API error parsing.
- Timeout handling with `AbortController`.
- Raw response mode for streaming endpoints.
- Streaming multipart upload bodies.

The HTTP layer does not globally unwrap successful responses. This is intentional because Buble media/app endpoints use `{ data: ... }`, while chat endpoints intentionally preserve OpenAI, Anthropic, and Gemini-compatible response shapes.

## Errors

The SDK exposes:

- `BubleAPIError`: non-2xx public API errors.
- `BubleTimeoutError`: request or polling timeout.
- `BubleGenerationError`: failed generation task returned during `wait`.
- `BubleCanceledError`: canceled generation task returned during `wait`.

`BubleAPIError` includes `status`, `code`, `details`, and the original `Response` when available.

## Resource Design

### Media Models

```ts
buble.mediaModels.list({ media_type: 'image' });
```

Maps to `GET /api/v1/media_models`. The response remains `{ data: MediaModel[] }`.

### Files

```ts
buble.files.upload(file, { file_type, model, mode });
```

Maps to `POST /api/v1/files`. Upload accepts local paths, `Blob`, `ArrayBuffer`, `Uint8Array`, and Node readable streams. Local paths and streams are sent as streaming multipart bodies to avoid reading large video files entirely into memory.

### Generations

```ts
buble.generations.create(body);
buble.generations.retrieve(id);
buble.generations.wait(id);
```

Generation bodies are flat JSON. The SDK performs a small local guard against known internal fields: `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, `media_type`, `images`, `image_input`, `video_input`, and `audio_input`.

The SDK intentionally allows unknown public root fields so newly configured model parameters can be used without waiting for an SDK release.

### Apps

```ts
buble.apps.list();
buble.apps.retrieve(app);
buble.apps.generations.create(app, body);
buble.apps.generations.wait(app, id);
```

App generation requests are flat JSON keyed by the app's public `input_parameters`. The SDK does not send or expose internal app workflow fields.

### Chat

```ts
buble.chat.models.list();
buble.chat.completions.create(body);
buble.chat.completions.stream(body);
buble.chat.messages.create(body);
buble.chat.messages.stream(body);
buble.chat.gemini.generateContent(model, body);
buble.chat.gemini.streamGenerateContent(model, body);
```

OpenAI and Anthropic streaming calls send `stream: true`. Gemini streaming calls the `:streamGenerateContent` route and does not use `stream: true`.

Gemini model keys can contain slashes. The SDK encodes each path segment independently, preserving slash-separated model keys while still escaping unsafe characters.

## Streaming

Streaming endpoints return `BubleStream`, an async iterable of parsed SSE events:

```ts
for await (const event of stream) {}
```

For convenience, `toTextStream()` extracts text deltas for OpenAI, Anthropic, and Gemini-compatible event shapes:

```ts
for await (const text of stream.toTextStream()) {}
```

The raw event stream remains available so protocol-specific metadata and tool events are not lost.

## Type Strategy

The SDK uses strong types for stable public structures:

- API envelopes.
- task status.
- media result assets.
- uploaded file response.
- app input parameters.
- common chat request fields.
- known error classes.

Model-specific generation controls remain open through `Record<string, unknown>`. This matches Buble's configuration-driven model onboarding model and avoids making SDK releases a bottleneck for new public model parameters.

## Verification Strategy

Tests use an injected `fetch` implementation to validate:

- Authorization headers.
- Path construction.
- OpenAI-style response preservation.
- API error parsing.
- forbidden public generation fields.
- flat generation request bodies.
- generation polling.
- Gemini slash model path handling.
- SSE text streaming.
- multipart upload body construction.

Real integration tests should be optional and gated behind environment variables because they consume Buble credits.

## Release Checklist

1. Verify package ownership for `@buble/sdk`.
2. Run `npm run build`.
3. Run `npm test`.
4. Run `npm run pack:check`.
5. Inspect the tarball file list.
6. Publish with `npm publish --provenance --access public`.

## Known Boundaries

- No browser support guarantee because API keys are server credentials.
- No public webhook support because the current Buble API uses polling.
- No idempotency-key helper because the current public API does not document idempotency keys.
- No hardcoded pricing helpers because server-side pricing configuration is not public API.
