# Buble SDK for Rust Technical Design

This SDK mirrors the TypeScript, Python, Go, Java, .NET, PHP, and Ruby SDKs in this monorepo while following Rust and Cargo conventions.

## Package Shape

- crates.io crate: `buble`
- Rust library name: `buble`
- Minimum Rust: 1.88
- Edition: 2021
- Runtime: async Rust with `reqwest`
- TLS: Rustls via `reqwest` with default features disabled
- Tests: Cargo tests with mocked HTTP via `wiremock`
- Documentation: rustdoc published automatically by docs.rs

## API Surface

`Client` exposes resource groups:

- `media_models()`
- `files()`
- `generations()`
- `apps()`
- `chat()`

Media and app generations expose `wait(...)` polling helpers. Stable media/app response fields are typed, and additional API fields are preserved through `#[serde(flatten)]` maps. Chat endpoints return `serde_json::Value` to preserve OpenAI, Anthropic, and Gemini-compatible protocol shapes.

## Request Semantics

Generation requests intentionally use a flat public API shape. Stable fields live on `CreateGenerationRequest`; model-specific parameters are supplied through `param(...)`. The SDK serializes those parameters at the JSON root and rejects internal workflow fields:

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

Apps accept flat `serde_json::Map<String, Value>` bodies because app input parameters are discovered dynamically through `apps().list(...)` and `apps().retrieve(...)`.

## Response Semantics

Media, file, and app endpoints preserve Buble's standard `{ data: ... }` envelope through `Envelope<T>`.

Chat endpoints preserve protocol-native response shapes as `serde_json::Value`. OpenAI-compatible, Anthropic-compatible, and Gemini-compatible responses are not globally wrapped or transformed.

## Streaming

Streaming APIs return boxed streams:

- `EventStream` yields parsed `SseEvent` values.
- `TextStream` yields extracted text chunks.

OpenAI-compatible and Anthropic-compatible endpoints set `stream: true` in the request body. Gemini streaming uses `stream_generate_content`; it does not add `stream: true` to `generate_content`.

## Error Model

- `Error::MissingApiKey`: no API key was configured.
- `Error::Api(ApiError)`: non-2xx API response with status, code, details, and raw body.
- `Error::Timeout`: HTTP or polling timeout.
- `Error::UnsupportedGenerationField`: local validation failure for internal generation fields.
- `Error::GenerationFailed`: terminal failed media generation.
- `Error::GenerationCanceled`: terminal canceled media generation.
- `Error::AppGenerationFailed`: terminal failed app generation.
- `Error::AppGenerationCanceled`: terminal canceled app generation.
- `Error::Stream`: server-sent-event parsing failure.

## Publishing

The Rust source remains under `rust/` in this monorepo. Publish from that directory to crates.io as `buble`. docs.rs automatically builds documentation from the crate after publication.

The GitHub release workflow uses tags with the `rust-v` prefix, for example `rust-v0.1.0`, verifies that `Cargo.toml` contains the matching version, runs tests and docs, performs `cargo publish --dry-run`, then publishes with `CARGO_REGISTRY_TOKEN`.
