# Buble SDK for Swift

Official Swift SDK for [Buble](https://buble.ai/), built for the [Buble public API](https://buble.ai/docs).

Use this SDK from server-side Swift applications and Apple platform apps with server-protected credentials to discover media models, upload source media, create asynchronous image and video generation tasks, run preconfigured Buble app workflows, and call chat models through OpenAI, Anthropic Messages, and Gemini-compatible API formats.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in public mobile binaries, browser code, or other client-side code unless requests are mediated through your own backend.

## Installation

After the Swift-only repository has been synced and tagged, add the package in Xcode or `Package.swift`:

```swift
.package(url: "https://github.com/bublehq/swift-sdk.git", from: "0.1.0")
```

Add the product to your target:

```swift
.product(name: "Buble", package: "swift-sdk")
```

The package requires Swift 5.9+ and supports macOS 12+, iOS 15+, tvOS 15+, and watchOS 8+. It uses Foundation and `URLSession` only, with no third-party runtime dependencies.

## Quick Start

Set your API key:

```bash
export BUBLE_API_KEY="sk_..."
```

The generation examples below create real Buble generation tasks and may consume credits.

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

The client reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

## Configuration

```swift
let client = try BubleClient(options: BubleClientOptions(
    apiKey: "sk_...",
    baseURL: URL(string: "https://buble.ai")!,
    timeout: 60,
    headers: ["X-Request-Id": "request-id"]
))
```

You may inject a custom `HTTPTransport` for tests or specialized networking environments. The default transport is `URLSessionHTTPTransport`.

## Discover Media Models

```swift
let models = try await client.mediaModels.list(mediaType: "video")

for model in models.data {
    print(model.model)
}
```

Use media model discovery as the source of truth for model keys, modes, required inputs, and public parameters. New Buble models can become available without an SDK release.

## Upload Files

```swift
let uploaded = try await client.files.upload(
    .fromFileURL(URL(fileURLWithPath: "reference.png"), contentType: "image/png"),
    options: UploadOptions(
        fileType: "image",
        model: "google/nano-banana",
        mode: "image_to_image"
    )
)

let task = try await client.generations.create(
    CreateGenerationRequest(model: "google/nano-banana")
        .mode("image_to_image")
        .prompt("Turn this reference into a polished ecommerce hero image.")
        .imageURLs([uploaded.data.url.absoluteString])
)
```

Uploads support local file URLs and in-memory `Data`. If `model` and `mode` are provided, Buble validates the upload against that model mode.

## Video Generation

```swift
let task = try await client.generations.create(
    try CreateGenerationRequest(model: "gork/grok-imagine-video")
        .mode("text_to_video")
        .prompt("A slow cinematic shot of a futuristic train station at sunrise.")
        .param("duration", "5s")
        .param("resolution", "480p")
        .param("aspect_ratio", "16:9")
)

let result = try await client.generations.wait(
    task.data.id,
    options: WaitOptions(interval: 2, timeout: 900)
)

print(result.data.result?.videos?.first?.url.absoluteString ?? "")
```

Generation request bodies use Buble's flat public API shape. Put model-specific controls in `param(...)`; the SDK serializes those controls at the JSON request root.

Do not send internal Buble fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Apps

```swift
let app = try await client.apps.retrieve("video-background-remover")
print(app.data.inputParameters)

let task = try await client.apps.generations.create(
    "video-background-remover",
    body: [
        "source_video": ["https://example.com/source.mp4"],
        "refine_foreground_edges": true,
        "subject_is_person": true
    ]
)

let result = try await client.apps.generations.wait(
    "video-background-remover",
    task.data.id
)
```

Apps are preconfigured workflows. Only send parameter names returned by `client.apps.list(...)` or `client.apps.retrieve(...)`.

## Chat

### OpenAI-Compatible

```swift
let completion = try await client.chat.completions.create([
    "model": "openai/gpt-5.4",
    "messages": [
        ["role": "user", "content": "Write a short launch summary."]
    ],
    "max_completion_tokens": 800
])

print(completion.value(at: ["choices", "0", "message", "content"])?.stringValue ?? "")
```

### Streaming

```swift
let stream = try await client.chat.completions.streamText([
    "model": "openai/gpt-5.4",
    "messages": [
        ["role": "user", "content": "Write one sentence at a time."]
    ]
])

for try await text in stream {
    print(text, terminator: "")
}
```

### Anthropic-Compatible

```swift
let message = try await client.chat.messages.create([
    "model": "openai/gpt-5.4",
    "system": "You are concise.",
    "messages": [
        ["role": "user", "content": "Summarize this release."]
    ],
    "max_tokens": 800
])
```

### Gemini-Compatible

```swift
let response = try await client.chat.gemini.generateContent(
    "openai/gpt-5.4",
    body: [
        "contents": [
            [
                "role": "user",
                "parts": [
                    ["text": "Write a short launch summary."]
                ]
            ]
        ]
    ]
)
```

Gemini streaming uses `streamGenerateContent`, not `stream: true` on `generateContent`.

Chat methods preserve protocol-native response shapes as `JSONValue`.

## Error Handling

```swift
do {
    _ = try await client.generations.retrieve("task_id")
} catch BubleError.api(let error) {
    print(error.statusCode)
    print(error.code ?? "")
    print(error.message)
    print(error.details ?? .null)
}

do {
    _ = try await client.generations.wait("task_id")
} catch BubleError.generationFailed(let task) {
    print(task.error?.message ?? "Generation failed")
}
```

## Live Smoke Test

The live smoke command calls discovery and chat paths and may create billable tasks if you extend it. Run it only with a valid API key:

```bash
cd swift
BUBLE_API_KEY=sk_... swift run BubleLiveSmoke
```

## Publishing

Swift Package Manager consumes Git repositories directly. This SDK should be published through the Swift-only repository `https://github.com/bublehq/swift-sdk`, whose root is the contents of `swift/`.

From this monorepo, the sync workflow pushes `swift/` to the Swift-only repository. The release workflow listens for tags such as `swift-v0.1.0`, validates the package, syncs `main`, and pushes the Swift Package Manager tag `0.1.0` to the Swift-only repository.

Consumers should depend on:

```swift
.package(url: "https://github.com/bublehq/swift-sdk.git", from: "0.1.0")
```

Swift package versions are Git tags. After a tag such as `0.1.0` is published, fixes should use a new semver tag such as `0.1.1`.

## License

MIT. See `LICENSE`.
