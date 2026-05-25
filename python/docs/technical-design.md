# buble-ai Technical Design

## Purpose

`buble-ai` is the official Python SDK for the Buble AI public API. It packages the stable public API contract into a Pythonic client without hardcoding every model, provider, or app-specific option.

The public API is configuration-driven. Media models, modes, app inputs, chat capabilities, and model parameters can change without an SDK release. The SDK therefore treats discovery endpoints as the source of truth:

- `/api/v1/media_models`
- `/api/v1/apps`
- `/api/v1/models`

## Package Naming

The PyPI distribution name is `buble-ai`. The Python import package is `buble_ai`.

This avoids conflict with the existing `buble` package on PyPI and makes the AI API purpose explicit.

## Runtime

- Python `>=3.9`
- Runtime dependency: `httpx>=0.27,<1`
- Build backend: `hatchling`
- Typed package marker: `py.typed`

## Public API

```python
from buble_ai import Buble, AsyncBuble
```

The synchronous client is intended for scripts, workers, and standard server environments. The asynchronous client is intended for async servers such as FastAPI or async task workers.

## Resource Model

The SDK mirrors the public API:

- `client.media_models.list()`
- `client.files.upload()`
- `client.generations.create()`
- `client.generations.retrieve()`
- `client.generations.wait()`
- `client.apps.list()`
- `client.apps.retrieve()`
- `client.apps.generations.create()`
- `client.apps.generations.wait()`
- `client.chat.models.list()`
- `client.chat.completions.create()`
- `client.chat.completions.stream()`
- `client.chat.messages.create()`
- `client.chat.gemini.generate_content()`

## Response Shapes

The SDK does not globally unwrap responses.

Media and app endpoints return Buble envelopes such as:

```python
{"data": ...}
```

Chat endpoints preserve protocol-native response shapes:

- OpenAI-compatible chat completions
- Anthropic-compatible messages
- Gemini-compatible generateContent

## Type Strategy

Stable public structures use `TypedDict` definitions. Model-specific controls remain open through `**params`.

This allows newly configured Buble models and app parameters to work without requiring SDK changes.

## Uploads

`files.upload()` supports:

- file paths
- `Path`
- `bytes`
- `bytearray`
- binary file objects

Path inputs are opened as binary streams and closed after the request. This avoids loading large videos fully into memory.

## Polling

`generations.wait()` and `apps.generations.wait()` poll until a terminal status:

- `success`: return task envelope
- `failed`: raise `BubleGenerationError`
- `canceled`: raise `BubleCanceledError`
- timeout: raise `BubleTimeoutError`

## Streaming

Streaming endpoints expose raw SSE events and text helpers:

```python
for event in client.chat.completions.stream(...):
    ...

for text in client.chat.completions.stream_text(...):
    ...
```

The SDK extracts text deltas for OpenAI, Anthropic, and Gemini-compatible streams while preserving raw events for advanced users.

## Gemini Model Paths

Gemini-compatible routes accept model keys that can contain slashes, such as `openai/gpt-5.5`. The SDK encodes each path segment separately so slashes remain route separators while unsafe characters are escaped.

## Error Handling

The SDK exposes:

- `BubleAPIError`
- `BubleTimeoutError`
- `BubleGenerationError`
- `BubleCanceledError`

`BubleAPIError` carries `status_code`, `code`, `message`, `details`, and the original response.

## Verification

Tests should cover:

- auth headers
- API error parsing
- media model discovery
- flat generation bodies
- forbidden internal generation fields
- polling
- app workflows
- multipart file upload
- chat response preservation
- Gemini slash model paths
- SSE parsing
- sync and async clients

## Release

Local release:

```bash
python -m pip install -U build twine
python -m build
python -m twine check dist/*
python -m twine upload dist/*
```

Recommended long-term release path is PyPI Trusted Publishing through GitHub Actions using OIDC.

