# Buble Rust SDK

Official Rust SDK for [Buble](https://buble.ai/), built for the [Buble public API](https://buble.ai/docs).

Use this SDK from server-side Rust applications to discover media models, upload source media, create asynchronous image and video generation tasks, run preconfigured Buble app workflows, and call chat models through OpenAI, Anthropic Messages, and Gemini-compatible API formats.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in browser, mobile, or other client-side code.

## Installation

After publication to crates.io:

```bash
cargo add buble
```

Or add it to `Cargo.toml`:

```toml
[dependencies]
buble = "0.1.0"
```

The crate requires Rust 1.88+ and uses async Rust with `reqwest` and Rustls TLS.

## Quick Start

Set your API key:

```bash
export BUBLE_API_KEY="sk_..."
```

The generation examples below create real Buble generation tasks and may consume credits.

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

The client reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

## Configuration

```rust
use std::time::Duration;

let client = buble::Client::builder()
    .api_key("sk_...")
    .base_url("https://buble.ai")
    .timeout(Duration::from_secs(60))
    .build()?;
```

You may also pass an externally configured `reqwest::Client`:

```rust
let http = reqwest::Client::builder().build()?;
let client = buble::Client::builder()
    .api_key("sk_...")
    .http_client(http)
    .build()?;
```

## Discover Media Models

```rust
let models = client.media_models().list(Some("video")).await?;

for model in models.data {
    println!("{}", model.model);
}
```

Use media model discovery as the source of truth for model keys, modes, required inputs, and public parameters. New Buble models can become available without an SDK release.

## Upload Files

```rust
let uploaded = client
    .files()
    .upload(
        buble::FileUpload::from_path("reference.png").content_type("image/png"),
        buble::UploadOptions::new()
            .file_type("image")
            .model("google/nano-banana")
            .mode("image_to_image"),
    )
    .await?;

let task = client
    .generations()
    .create(
        buble::CreateGenerationRequest::new("google/nano-banana")
            .mode("image_to_image")
            .prompt("Turn this reference into a polished ecommerce hero image.")
            .image_urls([uploaded.data.url]),
    )
    .await?;
```

Uploads support local paths and byte buffers. If `model` and `mode` are provided, Buble validates the upload against that model mode.

## Video Generation

```rust
use std::time::Duration;

let task = client
    .generations()
    .create(
        buble::CreateGenerationRequest::new("gork/grok-imagine-video")
            .mode("text_to_video")
            .prompt("A slow cinematic shot of a futuristic train station at sunrise.")
            .param("duration", "5s")?
            .param("resolution", "480p")?
            .param("aspect_ratio", "16:9")?,
    )
    .await?;

let result = client
    .generations()
    .wait(
        &task.data.id,
        buble::WaitOptions::new()
            .interval(Duration::from_secs(2))
            .timeout(Duration::from_secs(900)),
    )
    .await?;
```

Generation request bodies use Buble's flat public API shape. Put model-specific controls in `param(...)`; the SDK serializes those controls at the JSON request root.

Do not send internal Buble fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Apps

```rust
let app = client.apps().retrieve("video-background-remover").await?;
println!("{:?}", app.data.input_parameters);

let mut body = serde_json::Map::new();
body.insert(
    "source_video".to_string(),
    serde_json::json!(["https://example.com/source.mp4"]),
);

let task = client
    .apps()
    .generations()
    .create("video-background-remover", body)
    .await?;

let result = client
    .apps()
    .generations()
    .wait("video-background-remover", &task.data.id, buble::WaitOptions::default())
    .await?;
```

Apps are preconfigured workflows. Only send parameter names returned by `client.apps().list(...)` or `client.apps().retrieve(...)`.

## Chat

### OpenAI-Compatible

```rust
let completion = client
    .chat()
    .completions()
    .create(serde_json::json!({
        "model": "openai/gpt-5.4",
        "messages": [
            { "role": "user", "content": "Write a short launch summary." }
        ],
        "max_completion_tokens": 800
    }))
    .await?;
```

### Streaming

```rust
use futures_util::StreamExt;

let mut stream = client
    .chat()
    .completions()
    .stream_text(serde_json::json!({
        "model": "openai/gpt-5.4",
        "messages": [
            { "role": "user", "content": "Write one sentence at a time." }
        ]
    }))
    .await?;

while let Some(chunk) = stream.next().await {
    print!("{}", chunk?);
}
```

### Anthropic-Compatible

```rust
let message = client
    .chat()
    .messages()
    .create(serde_json::json!({
        "model": "openai/gpt-5.4",
        "system": "You are concise.",
        "messages": [
            { "role": "user", "content": "Summarize this release." }
        ],
        "max_tokens": 800
    }))
    .await?;
```

### Gemini-Compatible

```rust
let response = client
    .chat()
    .gemini()
    .generate_content(
        "openai/gpt-5.4",
        serde_json::json!({
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        { "text": "Write a short launch summary." }
                    ]
                }
            ]
        }),
    )
    .await?;
```

Gemini streaming uses `stream_generate_content`, not `stream: true` on `generate_content`.

Chat methods preserve protocol-native response shapes as `serde_json::Value`.

## Error Handling

```rust
match client.generations().retrieve("task_id").await {
    Ok(task) => println!("{task:#?}"),
    Err(buble::Error::Api(error)) => {
        eprintln!("{} {:?} {}", error.status, error.code, error.message);
    }
    Err(error) => return Err(error),
}

match client.generations().wait("task_id", buble::WaitOptions::default()).await {
    Ok(task) => println!("{task:#?}"),
    Err(buble::Error::GenerationFailed { task, .. }) => {
        eprintln!("{:?}", task.error);
    }
    Err(error) => return Err(error),
}
```

## Development

```bash
cd rust
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features
cargo package
```

Live smoke test:

```bash
BUBLE_API_KEY=sk_... cargo run --example live_smoke
```

The live smoke test calls discovery and chat endpoints only and does not create billable generation tasks.

## Publishing Checklist

crates.io package identity:

- Crate name: `buble`
- Library name: `buble`
- License: MIT
- Homepage: `https://buble.ai/`
- Documentation: `https://docs.rs/buble`

Local verification:

```bash
cd rust
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features
cargo publish --dry-run
```

Publish:

```bash
cargo publish
```

crates.io versions are immutable. After `0.1.0` is published, fixes must use a new version such as `0.1.1`. docs.rs builds package documentation automatically after crates.io publication.
