# ``Buble``

Use the Buble Swift SDK to call [Buble](https://buble.ai/) from Swift applications through the [Buble public API](https://buble.ai/docs).

## Overview

The SDK provides a typed `BubleClient` for server-side Swift and Apple platform applications that need to discover media models, upload source media, create asynchronous image and video generation tasks, run preconfigured Buble app workflows, and call chat models through OpenAI, Anthropic Messages, and Gemini-compatible API formats.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in public mobile binaries, browser code, or other client-side code unless requests are mediated through your own backend.

```swift
import Buble

let client = try BubleClient.fromEnvironment()

let task = try await client.generations.create(
    try CreateGenerationRequest(model: "google/nano-banana")
        .mode("text_to_image")
        .prompt("A cinematic product photo of a matte black espresso cup")
        .param("aspect_ratio", "1:1")
        .param("output_format", "png")
)

let result = try await client.generations.wait(task.data.id)
print(result.data.result?.images?.first?.url.absoluteString ?? "")
```

## Topics

### Client

- ``BubleClient``
- ``BubleClientOptions``
- ``BubleError``

### Generation

- ``CreateGenerationRequest``
- ``GenerationsService``
- ``WaitOptions``

### Files and Apps

- ``FileUpload``
- ``FilesService``
- ``AppsService``
- ``AppGenerationsService``

### Chat

- ``ChatService``
- ``ChatCompletionsService``
- ``MessagesService``
- ``GeminiService``
