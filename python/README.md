# buble-ai

Official Python SDK for the Buble AI public API. Use it from server-side Python code to create AI image and video generation tasks, run preconfigured Buble apps, upload source media, and call Buble chat models through OpenAI, Anthropic, or Gemini-compatible endpoints.

`buble-ai` is not related to the existing `buble` package on PyPI.

Keep your API key on the server. Do not expose `BUBLE_API_KEY` in browser or client-side code.

## Installation

```bash
pip install buble-ai
```

## Quick Start

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

The client reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

## Discover Media Models

```python
models = client.media_models.list(media_type="video")

for model in models["data"]:
    print(model["model"], [op["mode"] for op in model.get("operations", [])])
```

Use `media_models.list()` as the source of truth for model keys, modes, required inputs, and public parameters.

## Upload Files

```python
uploaded = client.files.upload(
    "reference.png",
    file_type="image",
    model="google/nano-banana",
    mode="image_to_image",
)

task = client.generations.create(
    model="google/nano-banana",
    mode="image_to_image",
    prompt="Turn this reference into a polished ecommerce hero image.",
    image_urls=[uploaded["data"]["url"]],
)
```

Uploads support paths, bytes, bytearray, and binary file objects. Paths are streamed from disk instead of being read fully into memory.

## Video Generation

```python
task = client.generations.create(
    model="doubao/seedance-2.0-fast",
    mode="text_to_video",
    prompt="A cinematic wide shot of a futuristic train station at sunrise.",
    duration="8s",
    resolution="720p",
    aspect_ratio="16:9",
)

result = client.generations.wait(task["data"]["id"], interval=2.0, timeout=600.0)
print(result["data"]["result"]["videos"][0]["url"])
```

Generation request bodies are flat JSON. Do not send internal Buble fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Apps

```python
app = client.apps.retrieve("video-background-remover")
print(app["data"]["input_parameters"])

task = client.apps.generations.create(
    "video-background-remover",
    source_video=["https://example.com/source.mp4"],
    refine_foreground_edges=True,
    subject_is_person=True,
)

result = client.apps.generations.wait("video-background-remover", task["data"]["id"])
print(result["data"]["result"]["videos"][0]["url"])
```

Apps are preconfigured workflows. Only send parameter names returned by `apps.list()` or `apps.retrieve()`.

## Chat

### OpenAI-Compatible

```python
completion = client.chat.completions.create(
    model="openai/gpt-5.5",
    messages=[{"role": "user", "content": "Write a short launch summary."}],
    reasoning=True,
    max_completion_tokens=800,
)

print(completion["choices"][0]["message"]["content"])
```

### Streaming

```python
for text in client.chat.completions.stream_text(
    model="openai/gpt-5.5",
    messages=[{"role": "user", "content": "Write one sentence at a time."}],
):
    print(text, end="")
```

### Anthropic-Compatible

```python
message = client.chat.messages.create(
    model="openai/gpt-5.5",
    system="You are concise.",
    messages=[{"role": "user", "content": "Summarize this release."}],
    max_tokens=800,
)
```

### Gemini-Compatible

```python
response = client.chat.gemini.generate_content(
    "openai/gpt-5.5",
    contents=[
        {
            "role": "user",
            "parts": [{"text": "Write a short launch summary."}],
        }
    ],
)
```

Gemini streaming uses `stream_generate_content`, not `stream=True` on `generate_content`.

## Async Client

```python
from buble_ai import AsyncBuble

async with AsyncBuble() as client:
    models = await client.chat.models.list()
```

## Error Handling

```python
from buble_ai import BubleAPIError, BubleGenerationError

try:
    client.generations.create(model="missing/model", mode="text_to_image")
except BubleAPIError as error:
    print(error.status_code, error.code, error.message, error.details)

try:
    client.generations.wait("task_id")
except BubleGenerationError as error:
    print(error.task)
```

## Development

```bash
python -m pip install -e ".[dev]"
pytest
python -m build
python -m twine check dist/*
```

Live smoke test:

```bash
BUBLE_API_KEY=sk_... python scripts/live_smoke.py
```

The live smoke test does not create billable generation tasks.

