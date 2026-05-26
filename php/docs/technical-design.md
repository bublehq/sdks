# Buble SDK for PHP Technical Design

This SDK mirrors the TypeScript, Python, Go, Java, and .NET SDKs in this monorepo while following PHP and Composer conventions.

## Package Shape

- Composer package: `buble/sdk`
- Namespace: `Buble\`
- Minimum PHP: 8.2
- Runtime extensions: `ext-curl`, `ext-json`
- Autoloading: PSR-4
- Tests: PHPUnit
- Static checks: PHPStan and PHP_CodeSniffer

## API Surface

`BubleClient` exposes resource groups:

- `mediaModels()`
- `files()`
- `generations()`
- `apps()`
- `chat()`

Media and app generations expose `wait(...)` polling helpers. PHP methods return associative arrays to preserve Buble's response shape and avoid creating brittle DTOs around configuration-driven model/app metadata.

## Request Semantics

Generation requests intentionally use a flat public API shape. Stable fields live on `CreateGenerationRequest`; model-specific parameters are supplied through `withParam(...)` or `withParams(...)`. The SDK serializes those parameters at the JSON root and rejects internal workflow fields:

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

Apps accept flat arrays because app input parameters are discovered dynamically through `apps()->list()` and `apps()->retrieve(...)`.

## Response Semantics

Media, file, and app endpoints preserve Buble's standard `{ data: ... }` envelope as associative arrays.

Chat endpoints preserve protocol-native response shapes as associative arrays. OpenAI-compatible, Anthropic-compatible, and Gemini-compatible responses are not globally wrapped or transformed.

## Streaming

Streaming APIs return PHP generators:

- raw SSE events as `Buble\Streaming\SseEvent`
- extracted text chunks through `streamText(...)`

Gemini streaming uses `streamGenerateContent`; it does not add `stream: true` to `generateContent`.

## Error Model

- `Buble\Exception\BubleException`: SDK base exception.
- `Buble\Exception\ApiException`: non-2xx API response with status, code, details, and raw body.
- `Buble\Exception\TimeoutException`: HTTP or polling timeout.
- `Buble\Exception\UnsupportedGenerationFieldException`: local validation failure for internal generation fields.
- `Buble\Exception\GenerationFailedException`: terminal failed generation.
- `Buble\Exception\GenerationCanceledException`: terminal canceled generation.

## Publishing

The PHP source remains under `php/` in this monorepo. Packagist should index a PHP-only split repository, such as `github.com/bublehq/php-sdk`, whose root contains this directory's `composer.json`. Do not submit the monorepo root to Packagist because consumers would install unrelated npm, Python, Go, Java, and .NET files.
