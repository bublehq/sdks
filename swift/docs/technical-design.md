# Buble SDK for Swift Technical Design

This SDK mirrors the TypeScript, Python, Go, Java, .NET, PHP, Ruby, and Rust SDKs in this monorepo while following Swift Package Manager conventions.

## Package Shape

- Swift package name: `Buble`
- Library product: `Buble`
- Import name: `Buble`
- Swift tools version: 5.9
- Platforms: macOS 12+, iOS 15+, tvOS 15+, watchOS 8+
- Runtime dependencies: Foundation and URLSession only
- Tests: XCTest with injected HTTP transport
- Documentation: package README plus DocC overview in `Sources/Buble/Buble.docc`

## API Surface

`BubleClient` exposes resource groups:

- `mediaModels`
- `files`
- `generations`
- `apps`
- `chat`

Media and app generations expose `wait(...)` polling helpers. Stable media/app response fields are typed, and chat endpoints return `JSONValue` to preserve OpenAI, Anthropic, and Gemini-compatible protocol shapes.

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

Apps accept flat `[String: JSONValue]` bodies because app input parameters are discovered dynamically through `apps.list(...)` and `apps.retrieve(...)`.

## Response Semantics

Media, file, and app endpoints preserve Buble's standard `{ data: ... }` envelope through `Envelope<T>`.

Chat endpoints preserve protocol-native response shapes as `JSONValue`. OpenAI-compatible, Anthropic-compatible, and Gemini-compatible responses are not globally wrapped or transformed.

## Streaming

Streaming APIs return `AsyncThrowingStream` values:

- raw SSE events as `ServerSentEvent`
- extracted text chunks through `streamText(...)`

OpenAI-compatible and Anthropic-compatible endpoints set `stream: true` in the request body. Gemini streaming uses `streamGenerateContent`; it does not add `stream: true` to `generateContent`.

## Error Model

- `BubleError.missingAPIKey`: no API key was configured.
- `BubleError.api(APIError)`: non-2xx API response with status, code, details, and raw body.
- `BubleError.timeout`: HTTP or polling timeout.
- `BubleError.unsupportedGenerationField`: local validation failure for internal generation fields.
- `BubleError.generationFailed`: terminal failed media generation.
- `BubleError.generationCanceled`: terminal canceled media generation.
- `BubleError.appGenerationFailed`: terminal failed app generation.
- `BubleError.appGenerationCanceled`: terminal canceled app generation.
- `BubleError.stream`: server-sent-event parsing failure.

## Publishing

The Swift source remains under `swift/` in this monorepo. Swift Package Manager should consume a Swift-only split repository, `github.com/bublehq/swift-sdk`, whose root contains this directory's `Package.swift`. Do not point Swift Package Manager consumers at the monorepo root because it is not the Swift package root.

The GitHub sync workflow pushes `swift/` to the Swift-only repository. The release workflow uses tags with the `swift-v` prefix, for example `swift-v0.1.0`, validates the package, syncs `main`, and then pushes the semver tag `0.1.0` to the Swift-only repository.
