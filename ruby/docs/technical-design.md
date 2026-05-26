# Buble Ruby SDK Technical Design

## Goals

The Ruby SDK mirrors the public Buble API in the same style as the existing JavaScript, Python, Go, Java, .NET, and PHP SDKs.

The SDK should:

- Keep the public API shape close to Buble's HTTP API.
- Preserve protocol-native chat response shapes.
- Use flat generation request bodies.
- Reject internal Buble workflow fields before sending requests.
- Avoid runtime dependencies outside the Ruby standard library.
- Be safe for server-side use and never encourage client-side API key exposure.

## Package Shape

The gem is named `buble` and exposes the `Buble` namespace.

Primary entry point:

```ruby
require "buble"

client = Buble::Client.new
```

The package root contains the gemspec and build metadata. Runtime source lives under `lib/`.

## HTTP Layer

`Buble::HTTP` is a small wrapper around `Net::HTTP`.

Responsibilities:

- Resolve base URL and paths.
- Add bearer token authentication.
- Encode query strings.
- Encode JSON request bodies.
- Decode JSON responses.
- Raise `Buble::APIError` for non-2xx responses.
- Send multipart file uploads.
- Stream SSE response lines.

The SDK intentionally avoids Faraday or other HTTP dependencies. This keeps installation lightweight and reduces dependency surface for Rails and non-Rails server applications.

## Resources

Resources map directly to API areas:

- `Buble::MediaModelsResource`
- `Buble::FilesResource`
- `Buble::GenerationsResource`
- `Buble::AppsResource`
- `Buble::AppGenerationsResource`
- `Buble::ChatResource`
- `Buble::ChatModelsResource`
- `Buble::ChatCompletionsResource`
- `Buble::MessagesResource`
- `Buble::GeminiResource`

Responses are Ruby Hashes with string keys. This preserves Buble API response shapes and avoids symbolizing arbitrary server-provided keys.

## Generation Requests

Generation requests use keyword arguments for stable fields and `**params` for model-specific controls:

```ruby
client.generations.create(
  model: "google/nano-banana",
  mode: "text_to_image",
  prompt: "A product photo",
  aspect_ratio: "1:1",
  output_format: "png"
)
```

The resulting HTTP body is flat:

```json
{
  "model": "google/nano-banana",
  "mode": "text_to_image",
  "prompt": "A product photo",
  "aspect_ratio": "1:1",
  "output_format": "png"
}
```

The SDK rejects internal fields:

- `input`
- `options`
- `scene`
- `sub_mode_id`
- `subModeId`
- `provider`
- `mediaType`
- `media_type`
- `images`
- `image_input`
- `video_input`
- `audio_input`

## Streaming

`Buble::Streaming::SSEParser` parses server-sent event lines into `Buble::Streaming::Event` objects.

Text helpers extract deltas for:

- OpenAI-compatible chat: `choices[0].delta.content`
- Anthropic-compatible messages: `delta.text`
- Gemini-compatible chat: `candidates[0].content.parts[0].text`

The lower-level `stream` APIs expose parsed SSE events for callers that need protocol details.

## Errors

The error hierarchy is:

- `Buble::Error`
- `Buble::APIError`
- `Buble::TimeoutError`
- `Buble::GenerationFailedError`
- `Buble::GenerationCanceledError`
- `Buble::UnsupportedGenerationFieldError`

`APIError` carries HTTP status, API error code, details, and raw response body.

## Testing

Unit tests use Minitest and `FakeTransport`.

Coverage focuses on:

- Request paths and bodies.
- Flat generation request serialization.
- Forbidden generation field rejection.
- Wait polling behavior.
- Multipart upload shape.
- App generation paths.
- Chat response preservation.
- SSE parsing and text extraction.

Live smoke tests are intentionally limited to low-cost discovery and chat checks.
