# Buble SDK for .NET Technical Design

This SDK mirrors the TypeScript, Python, Go, and Java SDKs in this monorepo while following .NET conventions.

## Package Shape

- Package ID: `Buble.SDK`
- Namespace: `Buble.Sdk`
- Assembly: `Buble.Sdk`
- Target frameworks: `netstandard2.0` and `net8.0`
- HTTP transport: `HttpClient`
- JSON: `System.Text.Json`
- Streaming: `IAsyncEnumerable<T>`

## API Surface

`BubleClient` exposes resource groups:

- `MediaModels`
- `Files`
- `Generations`
- `Apps`
- `Chat`

Methods are asynchronous and use the .NET `Async` suffix. Long-running media and app generations expose `WaitAsync` polling helpers.

## Request Semantics

Generation requests intentionally use a flat public API shape. Stable fields live on `CreateGenerationRequest`; model-specific parameters are supplied through `WithParam(...)` or `Params`. The SDK serializes those parameters at the JSON root and rejects internal workflow fields:

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

Apps accept flat dictionaries because app input parameters are discovered dynamically through `Apps.ListAsync()` and `Apps.RetrieveAsync(...)`.

## Response Semantics

Media, file, and app endpoints preserve Buble's standard `{ data: ... }` envelope through `Envelope<T>`.

Chat endpoints preserve protocol-native response shapes as `JsonObject`. OpenAI-compatible, Anthropic-compatible, and Gemini-compatible responses are not globally wrapped or transformed.

## Error Model

- `BubleException`: SDK base exception.
- `BubleApiException`: non-2xx API response with status, code, details, and raw body.
- `BubleTimeoutException`: HTTP or polling timeout.
- `UnsupportedGenerationFieldException`: local validation failure for internal generation fields.
- `GenerationFailedException`: terminal failed generation.
- `GenerationCanceledException`: terminal canceled generation.

## Publishing

The project is configured for `dotnet pack` and NuGet.org publication. The `.csproj` includes package metadata, MIT license expression, package README inclusion, XML documentation generation, symbol package generation, project URL, and repository metadata.
