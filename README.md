# Buble SDKs

Official SDKs for the [Buble public API](https://buble.ai/docs).

This repository contains the SDKs for calling Buble from server-side applications. The SDKs support media model discovery, file uploads, asynchronous image and video generation, preconfigured Buble app workflows, and chat model calls through OpenAI, Anthropic Messages, and Gemini-compatible API formats.

The SDKs share the same API model across JavaScript/TypeScript, Python, Go, Rust, Swift, Java, .NET, PHP, and Ruby: discover capabilities from Buble, create generation tasks with the public flat request shape, poll asynchronous tasks until completion, and preserve protocol-native chat responses.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in browser or client-side code.

## SDK Packages

| Package | Install | Runtime | Source | Guide |
| --- | --- | --- | --- | --- |
| `@buble/sdk` | `npm install @buble/sdk` | Node.js 18+ | `npm/` | [npm README](npm/README.md), [npm](https://www.npmjs.com/package/@buble/sdk) |
| `buble-ai` | `pip install buble-ai` | Python 3.9+ | `python/` | [Python README](python/README.md), [PyPI](https://pypi.org/project/buble-ai/) |
| `github.com/bublehq/sdks/go` | `go get github.com/bublehq/sdks/go` | Go 1.22+ | `go/` | [Go README](go/README.md), [pkg.go.dev](https://pkg.go.dev/github.com/bublehq/sdks/go) |
| `buble` | `cargo add buble` | Rust 1.88+ | `rust/` | [Rust README](rust/README.md), [crates.io](https://crates.io/crates/buble), [docs.rs](https://docs.rs/buble) |
| `Buble` | Swift Package dependency | Swift 5.9+ | `swift/` | [Swift README](swift/README.md), [Swift package repo](https://github.com/bublehq/swift-sdk) after sync |
| `ai.buble:buble-sdk` | Maven / Gradle dependency | Java 11+ | `java/` | [Java README](java/README.md), [Maven Central](https://central.sonatype.com/artifact/ai.buble/buble-sdk) after publication |
| `Buble.SDK` | `dotnet add package Buble.SDK` | .NET Standard 2.0 / .NET 8+ | `dotnet/` | [.NET README](dotnet/README.md), [NuGet.org](https://www.nuget.org/packages/Buble.SDK) |
| `buble/sdk` | `composer require buble/sdk` | PHP 8.2+ with `ext-curl` and `ext-json` | `php/` | [PHP README](php/README.md), [Packagist](https://packagist.org/packages/buble/sdk) after publication |
| `buble` | `gem install buble` | Ruby 3.3+ | `ruby/` | [Ruby README](ruby/README.md), [RubyGems](https://rubygems.org/gems/buble) after publication |

## Quick Start

Set your API key:

```bash
export BUBLE_API_KEY="sk_..."
```

The generation examples below create real Buble generation tasks and may consume credits.

### JavaScript / TypeScript

Install:

```bash
npm install @buble/sdk
```

Quick start:

```ts
import { Buble } from '@buble/sdk';

const buble = new Buble({
  apiKey: process.env.BUBLE_API_KEY
});

const task = await buble.generations.create({
  model: 'google/nano-banana',
  mode: 'text_to_image',
  prompt: 'A cinematic product photo of a matte black espresso cup',
  aspect_ratio: '1:1',
  output_format: 'png'
});

const result = await buble.generations.wait(task.data.id);
console.log(result.data.result?.images?.[0]?.url);
```

The TypeScript SDK also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

### Python

Install:

```bash
pip install buble-ai
```

Quick start:

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

The Python SDK also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

### Go

Install:

```bash
go get github.com/bublehq/sdks/go
```

Quick start:

```go
package main

import (
	"context"
	"fmt"
	"log"

	buble "github.com/bublehq/sdks/go"
)

func main() {
	ctx := context.Background()
	client := buble.NewClient()

	task, err := client.Generations.Create(ctx, &buble.CreateGenerationRequest{
		Model:  "google/nano-banana",
		Mode:   "text_to_image",
		Prompt: "A cinematic product photo of a matte black espresso cup",
		Params: map[string]any{
			"aspect_ratio":  "1:1",
			"output_format": "png",
		},
	})
	if err != nil {
		log.Fatal(err)
	}

	result, err := client.Generations.Wait(ctx, task.Data.ID)
	if err != nil {
		log.Fatal(err)
	}
	if result.Data.Result != nil && len(result.Data.Result.Images) > 0 {
		fmt.Println(result.Data.Result.Images[0].URL)
	}
}
```

The Go SDK also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

Go API documentation is generated from package comments and exported symbols. After a tagged release is indexed, it is available on [pkg.go.dev](https://pkg.go.dev/github.com/bublehq/sdks/go).

### Rust

Install:

```bash
cargo add buble
```

Quick start:

```rust
use buble::{Client, CreateGenerationRequest, WaitOptions};

#[tokio::main]
async fn main() -> buble::Result<()> {
    let client = Client::from_env()?;

    let task = client
        .generations()
        .create(
            CreateGenerationRequest::new("google/nano-banana")
                .mode("text_to_image")
                .prompt("A cinematic product photo of a matte black espresso cup")
                .param("aspect_ratio", "1:1")?
                .param("output_format", "png")?,
        )
        .await?;

    let result = client
        .generations()
        .wait(&task.data.id, WaitOptions::default())
        .await?;

    if let Some(result) = result.data.result {
        if let Some(image) = result.images.first() {
            println!("{}", image.url);
        }
    }

    Ok(())
}
```

The Rust SDK also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted. API documentation is available on [docs.rs](https://docs.rs/buble), and the crate is published on [crates.io](https://crates.io/crates/buble).

### Swift

Add the Swift package after the Swift-only repository has been synced and tagged:

```swift
.package(url: "https://github.com/bublehq/swift-sdk.git", from: "0.1.0")
```

Add the product to your target:

```swift
.product(name: "Buble", package: "swift-sdk")
```

Quick start:

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

The Swift SDK also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted. It uses Foundation and `URLSession` only, with no third-party runtime dependencies. Swift Package Manager consumes the Swift-only repository `https://github.com/bublehq/swift-sdk`, whose root is the contents of `swift/`.

### Java

Install with Maven:

```xml
<dependency>
  <groupId>ai.buble</groupId>
  <artifactId>buble-sdk</artifactId>
  <version>0.1.0</version>
</dependency>
```

Or Gradle:

```gradle
implementation("ai.buble:buble-sdk:0.1.0")
```

Quick start:

```java
import ai.buble.sdk.BubleClient;
import ai.buble.sdk.Envelope;
import ai.buble.sdk.generations.CreateGenerationRequest;
import ai.buble.sdk.generations.GenerationTask;

public class Main {
    public static void main(String[] args) {
        BubleClient client = BubleClient.fromEnv();

        Envelope<GenerationTask> task = client.generations().create(
                CreateGenerationRequest.builder()
                        .model("google/nano-banana")
                        .mode("text_to_image")
                        .prompt("A cinematic product photo of a matte black espresso cup")
                        .param("aspect_ratio", "1:1")
                        .param("output_format", "png")
                        .build());

        Envelope<GenerationTask> result = client.generations().wait(task.getData().getId());
        System.out.println(result.getData().getResult().getImages().get(0).getUrl());
    }
}
```

The Java SDK also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted. It is configured for Maven Central publication with a release profile that produces the main JAR, sources JAR, Javadoc JAR, and GPG signatures. MVNRepository will index the artifact after Maven Central publication and indexing.

### .NET

Install:

```bash
dotnet add package Buble.SDK --version 0.1.2
```

Package Manager:

```powershell
Install-Package Buble.SDK -Version 0.1.2
```

Quick start:

```csharp
using Buble.Sdk;
using Buble.Sdk.Generations;

using var client = BubleClient.FromEnv();

var task = await client.Generations.CreateAsync(new CreateGenerationRequest
{
    Model = "google/nano-banana",
    Mode = "text_to_image",
    Prompt = "A cinematic product photo of a matte black espresso cup"
}.WithParam("aspect_ratio", "1:1").WithParam("output_format", "png"));

var result = await client.Generations.WaitAsync(task!.Data!.Id!);
Console.WriteLine(result.Data?.Result?.Images?[0].Url);
```

The .NET SDK exposes the `Buble.Sdk` namespace, targets `netstandard2.0` and `net8.0`, and also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted. `BubleClientOptions` supports custom API keys, base URLs, timeouts, and externally managed `HttpClient` instances for ASP.NET Core or other dependency-injection setups.

NuGet packaging is configured in `dotnet/src/Buble.Sdk/Buble.Sdk.csproj` with package metadata, README inclusion, XML documentation, and `.snupkg` symbol package generation.

### PHP

Install:

```bash
composer require buble/sdk
```

Quick start:

```php
<?php

use Buble\BubleClient;
use Buble\Generations\CreateGenerationRequest;

$client = BubleClient::fromEnv();

$task = $client->generations()->create(
    CreateGenerationRequest::make(
        model: 'google/nano-banana',
        mode: 'text_to_image',
        prompt: 'A cinematic product photo of a matte black espresso cup',
    )->withParam('aspect_ratio', '1:1')
     ->withParam('output_format', 'png')
);

$result = $client->generations()->wait($task['data']['id']);
echo $result['data']['result']['images'][0]['url'] . PHP_EOL;
```

The PHP SDK exposes the `Buble\` namespace, requires PHP 8.2+, `ext-curl`, and `ext-json`, and also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted. The client accepts `BubleClientOptions` or an options array for explicit server-side configuration.

Packagist publication should use a PHP-only split repository whose root is the contents of `php/`. Do not submit the monorepo root to Packagist.

### Ruby

Install:

```bash
gem install buble
```

Bundler:

```ruby
gem "buble"
```

Quick start:

```ruby
require "buble"

client = Buble::Client.new

task = client.generations.create(
  model: "google/nano-banana",
  mode: "text_to_image",
  prompt: "A cinematic product photo of a matte black espresso cup",
  aspect_ratio: "1:1",
  output_format: "png"
)

result = client.generations.wait(task.dig("data", "id"))
puts result.dig("data", "result", "images", 0, "url")
```

The Ruby SDK exposes the `Buble` namespace, requires Ruby 3.3+, has no runtime dependencies outside the Ruby standard library, and also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

## Supported API Areas

The SDKs mirror the public Buble API:

| Area | Endpoints |
| --- | --- |
| Media model discovery | `GET /api/v1/media_models` |
| File uploads | `POST /api/v1/files` |
| Media generations | `POST /api/v1/generations`, `GET /api/v1/generations/{id}` |
| App workflows | `GET /api/v1/apps`, `GET /api/v1/apps/{app}`, `POST /api/v1/apps/{app}/generations`, `GET /api/v1/apps/{app}/generations/{id}` |
| Chat models | `GET /api/v1/models` |
| OpenAI-compatible chat | `POST /api/v1/chat/completions` |
| Anthropic-compatible messages | `POST /api/v1/messages` |
| Gemini-compatible chat | `POST /api/v1beta/models/{model}:generateContent`, `POST /api/v1beta/models/{model}:streamGenerateContent` |

Media and app generation tasks are asynchronous. Create a task, then poll until the task reaches `success`, `failed`, or `canceled`.

Generation request bodies use the flat public API shape. Put model-specific controls such as `duration`, `resolution`, `aspect_ratio`, `output_format`, `web_search`, and `audio` at the request root.

Do not send internal workflow fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Compatibility Model

Buble's public API is configuration-driven. New media models, modes, app inputs, and chat model capabilities can become available without an SDK release.

Use the discovery endpoints as the source of truth:

- `mediaModels.list()` / `media_models.list()` for media model keys, modes, input requirements, and parameters.
- `apps.list()` and `apps.retrieve()` for app ids and input parameters.
- `chat.models.list()` for available chat models and capabilities.
- Java equivalents are `client.mediaModels().list(...)`, `client.apps().list()`, `client.apps().retrieve(...)`, and `client.chat().models().list()`.
- .NET equivalents are `client.MediaModels.ListAsync(...)`, `client.Apps.ListAsync()`, `client.Apps.RetrieveAsync(...)`, and `client.Chat.Models.ListAsync()`.
- PHP equivalents are `$client->mediaModels()->list(...)`, `$client->apps()->list()`, `$client->apps()->retrieve(...)`, and `$client->chat()->models()->list()`.
- Ruby equivalents are `client.media_models.list(...)`, `client.apps.list`, `client.apps.retrieve(...)`, and `client.chat.models.list`.
- Swift equivalents are `client.mediaModels.list(...)`, `client.apps.list()`, `client.apps.retrieve(...)`, and `client.chat.models.list()`.

The SDKs preserve protocol-native chat response shapes. OpenAI-compatible, Anthropic-compatible, and Gemini-compatible responses are not globally wrapped or transformed.

## Common Workflows

### Discover Media Models

Use model discovery before building production requests:

```ts
const models = await buble.mediaModels.list({ media_type: 'video' });
```

```python
models = client.media_models.list(media_type="video")
```

```go
models, err := client.MediaModels.List(ctx, "video")
if err != nil {
	log.Fatal(err)
}
```

```java
Envelope<List<MediaModel>> models = client.mediaModels().list("video");
```

```csharp
var models = await client.MediaModels.ListAsync(mediaType: "video");
```

```php
$models = $client->mediaModels()->list(mediaType: 'video');
```

```ruby
models = client.media_models.list(media_type: "video")
```

```swift
let models = try await client.mediaModels.list(mediaType: "video")
```

The response contains model keys, supported modes, required inputs, and accepted parameters.

### Upload Source Media

Upload source assets before image-to-image, image-to-video, video-to-video, or audio-assisted workflows:

```ts
const uploaded = await buble.files.upload('./reference.png', {
  file_type: 'image',
  model: 'google/nano-banana',
  mode: 'image_to_image'
});
```

```python
uploaded = client.files.upload(
    "reference.png",
    file_type="image",
    model="google/nano-banana",
    mode="image_to_image",
)
```

```go
uploaded, err := client.Files.Upload(
	ctx,
	buble.FileFromPath("./reference.png"),
	buble.WithFileType("image"),
	buble.WithUploadModel("google/nano-banana"),
	buble.WithUploadMode("image_to_image"),
)
if err != nil {
	log.Fatal(err)
}
```

```java
Envelope<UploadedFile> uploaded = client.files().upload(
        FileUpload.fromPath(Path.of("reference.png")),
        UploadOptions.builder()
                .fileType("image")
                .model("google/nano-banana")
                .mode("image_to_image")
                .build());
```

```csharp
var uploaded = await client.Files.UploadAsync(
    FileUpload.FromPath("reference.png", "image/png"),
    new UploadOptions
    {
        FileType = "image",
        Model = "google/nano-banana",
        Mode = "image_to_image"
    });
```

```php
$uploaded = $client->files()->upload(
    FileUpload::fromPath('reference.png', 'image/png'),
    new UploadOptions(fileType: 'image', model: 'google/nano-banana', mode: 'image_to_image')
);
```

```ruby
uploaded = client.files.upload(
  Buble::FileUpload.from_path("reference.png", content_type: "image/png"),
  file_type: "image",
  model: "google/nano-banana",
  mode: "image_to_image"
)
```

```swift
let uploaded = try await client.files.upload(
    .fromFileURL(URL(fileURLWithPath: "reference.png"), contentType: "image/png"),
    options: UploadOptions(fileType: "image", model: "google/nano-banana", mode: "image_to_image")
)
```

Pass the returned URL into fields such as `image_urls`, `start_frame`, `end_frame`, `video_urls`, or `audio_urls`.

### Run App Workflows

Use apps when you want a preconfigured workflow instead of selecting a model and mode directly:

```ts
const task = await buble.apps.generations.create('video-background-remover', {
  source_video: ['https://example.com/source.mp4'],
  refine_foreground_edges: true,
  subject_is_person: true
});
```

```python
task = client.apps.generations.create(
    "video-background-remover",
    source_video=["https://example.com/source.mp4"],
    refine_foreground_edges=True,
    subject_is_person=True,
)
```

```go
task, err := client.Apps.Generations.Create(ctx, "video-background-remover", map[string]any{
	"source_video":            []string{"https://example.com/source.mp4"},
	"refine_foreground_edges": true,
	"subject_is_person":       true,
})
if err != nil {
	log.Fatal(err)
}
```

```java
Envelope<AppGenerationTask> task = client.apps().generations().create(
        "video-background-remover",
        Map.of(
                "source_video", List.of("https://example.com/source.mp4"),
                "refine_foreground_edges", true,
                "subject_is_person", true
        ));
```

```csharp
var task = await client.Apps.Generations.CreateAsync(
    "video-background-remover",
    new Dictionary<string, object?>
    {
        ["source_video"] = new[] { "https://example.com/source.mp4" },
        ["refine_foreground_edges"] = true,
        ["subject_is_person"] = true
    });
```

```php
$task = $client->apps()->generations()->create('video-background-remover', [
    'source_video' => ['https://example.com/source.mp4'],
    'refine_foreground_edges' => true,
    'subject_is_person' => true,
]);
```

```ruby
task = client.apps.generations.create("video-background-remover", {
  "source_video" => ["https://example.com/source.mp4"],
  "refine_foreground_edges" => true,
  "subject_is_person" => true
})
```

```swift
let task = try await client.apps.generations.create("video-background-remover", body: [
    "source_video": ["https://example.com/source.mp4"],
    "refine_foreground_edges": true,
    "subject_is_person": true
])
```

Only send input parameter names returned by `apps.list()` or `apps.retrieve()`.

### Stream Chat Output

The SDKs expose raw server-sent events and text helpers for chat streaming.

```ts
const stream = await buble.chat.completions.stream({
  model: 'openai/gpt-5.5',
  messages: [{ role: 'user', content: 'Write a short launch summary.' }]
});

for await (const text of stream.toTextStream()) {
  process.stdout.write(text);
}
```

```python
for text in client.chat.completions.stream_text(
    model="openai/gpt-5.5",
    messages=[{"role": "user", "content": "Write a short launch summary."}],
):
    print(text, end="")
```

```go
stream, err := client.Chat.Completions.Stream(ctx, buble.ChatRequest{
	"model": "openai/gpt-5.5",
	"messages": []any{
		map[string]any{"role": "user", "content": "Write a short launch summary."},
	},
})
if err != nil {
	log.Fatal(err)
}
defer stream.Close()

for stream.Next() {
	fmt.Print(stream.Text())
}
if err := stream.Err(); err != nil {
	log.Fatal(err)
}
```

```java
try (BubleStream stream = client.chat().completions().stream(Map.of(
        "model", "openai/gpt-5.5",
        "messages", List.of(Map.of("role", "user", "content", "Write a short launch summary."))
))) {
    while (stream.next()) {
        System.out.print(stream.text());
    }
}
```

```csharp
await foreach (var text in client.Chat.Completions.StreamTextAsync(new Dictionary<string, object?>
{
    ["model"] = "openai/gpt-5.5",
    ["messages"] = new[]
    {
        new Dictionary<string, object?>
        {
            ["role"] = "user",
            ["content"] = "Write a short launch summary."
        }
    }
}))
{
    Console.Write(text);
}
```

```php
foreach ($client->chat()->completions()->streamText([
    'model' => 'openai/gpt-5.5',
    'messages' => [
        ['role' => 'user', 'content' => 'Write a short launch summary.'],
    ],
]) as $text) {
    echo $text;
}
```

```ruby
client.chat.completions.stream_text(
  model: "openai/gpt-5.5",
  messages: [
    { role: "user", content: "Write a short launch summary." }
  ]
).each do |text|
  print text
end
```

```swift
let stream = try await client.chat.completions.streamText([
    "model": "openai/gpt-5.5",
    "messages": [
        ["role": "user", "content": "Write a short launch summary."]
    ]
])

for try await text in stream {
    print(text, terminator: "")
}
```

## Repository Layout

```txt
.
├── npm/
│   ├── src/
│   ├── tests/
│   ├── examples/
│   └── docs/
├── go/
│   ├── *.go
│   ├── examples/
│   └── cmd/live-smoke/
├── rust/
│   ├── src/
│   ├── tests/
│   ├── examples/
│   └── docs/
├── swift/
│   ├── Sources/Buble/
│   ├── Tests/BubleTests/
│   ├── Examples/
│   └── docs/
├── java/
│   ├── src/
│   ├── examples/
│   └── docs/
├── dotnet/
│   ├── src/Buble.Sdk/
│   ├── tests/Buble.Sdk.Tests/
│   ├── examples/
│   ├── tools/Buble.Sdk.LiveSmoke/
│   └── docs/
├── php/
│   ├── src/
│   ├── tests/
│   ├── examples/
│   ├── tools/
│   └── docs/
├── ruby/
│   ├── lib/
│   ├── test/
│   ├── examples/
│   ├── tools/
│   └── docs/
└── python/
    ├── src/buble_ai/
    ├── tests/
    ├── examples/
    └── docs/
```

## Development

JavaScript / TypeScript:

```bash
cd npm
npm install
npm run typecheck
npm test
npm run build
npm run pack:check
```

Python:

```bash
cd python
python -m pip install -e ".[dev]"
pytest
python -m build
python -m twine check dist/*
```

Go:

```bash
cd go
go test ./...
go vet ./...
```

Rust:

```bash
cd rust
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features
cargo package
```

Swift:

```bash
cd swift
swift package dump-package
swift build
swift test
```

Java:

```bash
cd java
mvn test
mvn verify
mvn -P release -Dgpg.skip=true verify
```

Use the release profile without `-Dgpg.skip=true` only when GPG signing is configured and you are preparing a Maven Central release.

.NET:

```bash
cd dotnet
dotnet restore Buble.Sdk.sln
dotnet test Buble.Sdk.sln -c Release
dotnet pack src/Buble.Sdk/Buble.Sdk.csproj -c Release -o artifacts
```

PHP:

```bash
cd php
composer validate --strict
composer install
composer test
composer analyse
composer cs
```

Ruby:

```bash
cd ruby
bundle install
bundle exec rake test
bundle exec rubocop
gem build buble.gemspec
```

## Rust Publishing

The Rust SDK is published directly to crates.io as `buble`. docs.rs builds the API documentation automatically after crates.io publication.

Package links:

- crates.io: `https://crates.io/crates/buble`
- docs.rs: `https://docs.rs/buble`

Release prerequisites:

- Confirm the publishing account has a verified crates.io email address.
- Confirm the publishing account or Buble team owns the `buble` crate.
- Configure a crates.io API token as a GitHub Actions secret named `CARGO_REGISTRY_TOKEN`.
- Run formatting, Clippy, tests, docs, and `cargo publish --dry-run`.

Local verification:

```bash
cd rust
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features
cargo publish --dry-run
```

Publish through the release workflow with a Rust-specific monorepo tag:

```bash
git tag rust-v0.1.0
git push origin rust-v0.1.0
```

The workflow verifies that `Cargo.toml` has the matching package version, runs the same checks, performs a dry run, then publishes with `cargo publish`. crates.io versions are immutable; after `0.1.0` is published, fixes must use a new version such as `0.1.1`.

## Swift Publishing

The Swift SDK is published through Swift Package Manager by tagging a Swift-only Git repository. There is no central Swift Package Manager upload step.

Package repository:

- Swift Package: `https://github.com/bublehq/swift-sdk`

Because this repository is a multi-language monorepo, Swift consumers should use the Swift-only split repository whose root contains `Package.swift`, `Sources/`, `Tests/`, `Examples/`, `README.md`, and `LICENSE`. Do not point Swift Package Manager consumers at this monorepo root.

Before the first Swift release:

- Create or verify the Swift-only repository `https://github.com/bublehq/swift-sdk`.
- Add a deploy key with write access to that repository.
- Store the private deploy key in this monorepo as the GitHub Actions secret `SWIFT_SDK_DEPLOY_KEY`.
- Confirm the sync workflow can push `swift/` to the Swift-only repository root.

Local verification:

```bash
cd swift
swift package dump-package
swift build
swift test
```

Publish through the release workflow with a Swift-specific monorepo tag:

```bash
git tag swift-v0.1.0
git push origin swift-v0.1.0
```

The workflow validates the package, syncs `swift/` to `bublehq/swift-sdk`, and pushes the Swift Package Manager version tag `0.1.0` to the Swift-only repository. Swift package versions are Git tags; after `0.1.0` is published, fixes should use a new version such as `0.1.1`.

## Java Publishing

The Java SDK is published through Maven Central, not directly through MVNRepository. MVNRepository is an indexing site and will show `ai.buble:buble-sdk` after Maven Central publishes and indexes the artifact.

Before the first Java release:

- Verify the `ai.buble` namespace in Sonatype Central Portal.
- Configure a Central Portal token in `~/.m2/settings.xml` with server id `central`.
- Configure GPG signing with a public key available to Maven Central.
- Run `mvn clean verify` and `mvn -P release clean verify`.

Release command:

```bash
cd java
mvn -P release clean deploy
```

The Java `pom.xml` uses `autoPublish=false`, so review the deployment in Central Portal before publishing it. Maven Central versions are immutable; after `0.1.0` is published, fixes must use a new version such as `0.1.1`.

## .NET Publishing

The .NET SDK is published directly to NuGet.org as `Buble.SDK`.

Before the first .NET release:

- Ensure the `Buble.SDK` package ID is available or owned by the Buble NuGet.org account.
- If publishing under the Buble NuGet organization, reserve or transfer the `Buble.SDK` package ID to that organization before pushing new versions.
- Create a NuGet.org API key with permission to push `Buble.SDK`.
- Run the release build and inspect the generated `.nupkg` and `.snupkg`.

Release command:

```bash
cd dotnet
dotnet test Buble.Sdk.sln -c Release
dotnet pack src/Buble.Sdk/Buble.Sdk.csproj -c Release -o artifacts
dotnet nuget push artifacts/Buble.SDK.0.1.2.nupkg \
  --api-key "$NUGET_API_KEY" \
  --source https://api.nuget.org/v3/index.json
```

The package metadata points users to `https://buble.ai/` as the project website and includes the package README from `dotnet/README.md`. The project also produces `artifacts/Buble.SDK.0.1.2.snupkg`. If your NuGet client does not publish the symbol package together with the main package, push the `.snupkg` to the same source. NuGet package versions are immutable; after `0.1.2` is published, fixes must use a new version such as `0.1.3`.

## PHP Publishing

The PHP SDK is published to Packagist as `buble/sdk`.

Because this repository is a multi-language monorepo, publish the PHP SDK through a PHP-only split repository whose root contains the contents of `php/`. Do not submit this monorepo root to Packagist. The PHP package intentionally omits a `version` field from `composer.json`; Composer and Packagist derive versions from Git tags.

Before the first PHP release:

- Create or verify the PHP-only repository `https://github.com/bublehq/php-sdk`.
- Ensure that repository root contains `composer.json`, `src/`, `README.md`, `LICENSE`, `examples/`, and `docs/` after sync.
- Submit `https://github.com/bublehq/php-sdk` to Packagist, not `https://github.com/bublehq/sdks`.
- Configure the Packagist GitHub hook or GitHub App access so new tags are indexed automatically.

Release flow:

```bash
git subtree split --prefix=php -b php-release
git push git@github.com:bublehq/php-sdk.git php-release:main --force-with-lease
```

In the PHP-only repository:

```bash
git tag v0.1.0
git push origin v0.1.0
```

When using the recommended GitHub Actions split flow, tag releases in the monorepo with a PHP-specific prefix such as `php-v0.1.0`; the release workflow should push `v0.1.0` to the PHP-only repository for Packagist. Composer package versions are immutable after publication in practice because consumers can lock them, so publish fixes with a new version tag such as `v0.1.1`.

## Ruby Publishing

The Ruby SDK is published directly to RubyGems as `buble`.

Before the first Ruby release:

- Confirm `buble` is still available on RubyGems.
- Create or sign in to the Buble RubyGems.org account.
- Configure RubyGems Trusted Publishing for `buble`.
  - Repository owner: `bublehq`
  - Repository name: `sdks`
  - Workflow filename: `release-ruby-sdk.yml`
  - Environment: `release`
- Run tests, linting, and `gem build`.

Local verification:

```bash
cd ruby
bundle exec rake test
bundle exec rubocop
gem build buble.gemspec
```

RubyGems versions are immutable; after `0.1.0` is published, fixes must use a new version such as `0.1.1`.

Publish through the release workflow with a Ruby-specific monorepo tag:

```bash
git tag ruby-v0.1.0
git push origin ruby-v0.1.0
```

The workflow uses RubyGems Trusted Publishing through GitHub OIDC. It does not require a `RUBYGEMS_API_KEY` secret.

## Live Smoke Tests

Live smoke tests require `BUBLE_API_KEY`. They call discovery and error-handling paths and are intended to avoid creating billable generation tasks.

```bash
cd npm
BUBLE_API_KEY=sk_... npm run test:live
```

```bash
cd python
BUBLE_API_KEY=sk_... python scripts/live_smoke.py
```

```bash
cd go
BUBLE_API_KEY=sk_... go run ./cmd/live-smoke
```

```bash
cd rust
BUBLE_API_KEY=sk_... cargo run --example live_smoke
```

```bash
cd swift
BUBLE_API_KEY=sk_... swift run BubleLiveSmoke
```

```bash
cd dotnet
BUBLE_API_KEY=sk_... dotnet run --project tools/Buble.Sdk.LiveSmoke -c Release
```

```bash
cd php
BUBLE_API_KEY=sk_... php tools/live-smoke.php
```

```bash
cd ruby
BUBLE_API_KEY=sk_... ruby -Ilib tools/live_smoke.rb
```

## License

MIT. See the package-specific license files in `npm/LICENSE`, `python/LICENSE`, `go/LICENSE`, `rust/LICENSE`, `swift/LICENSE`, `java/LICENSE`, `dotnet/LICENSE`, `php/LICENSE`, and `ruby/LICENSE`.
