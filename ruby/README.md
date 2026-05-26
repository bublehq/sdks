# Buble SDK for Ruby

Official Ruby SDK for [Buble](https://buble.ai/), built for the [Buble public API](https://buble.ai/docs).

Use this SDK from server-side Ruby applications to discover media models, upload source media, create asynchronous image and video generation tasks, run preconfigured Buble app workflows, and call chat models through OpenAI, Anthropic Messages, and Gemini-compatible API formats.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in browser, mobile, or other client-side code.

## Installation

After publication to RubyGems:

```bash
gem install buble
```

Bundler:

```ruby
gem "buble"
```

The gem requires Ruby 3.3+ and has no runtime dependencies outside the Ruby standard library.

## Quick Start

Set your API key:

```bash
export BUBLE_API_KEY="sk_..."
```

The generation examples below create real Buble generation tasks and may consume credits.

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

The client reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

## Configuration

```ruby
client = Buble::Client.new(
  api_key: "sk_...",
  base_url: "https://buble.ai",
  timeout: 60,
  headers: {
    "X-Request-Id" => "request-id"
  }
)
```

## Discover Media Models

```ruby
models = client.media_models.list(media_type: "video")

models.fetch("data", []).each do |model|
  puts model["model"]
end
```

Use media model discovery as the source of truth for model keys, modes, required inputs, and public parameters. New Buble models can become available without an SDK release.

## Upload Files

```ruby
upload = Buble::FileUpload.from_path("reference.png", content_type: "image/png")

uploaded = client.files.upload(
  upload,
  file_type: "image",
  model: "google/nano-banana",
  mode: "image_to_image"
)

task = client.generations.create(
  model: "google/nano-banana",
  mode: "image_to_image",
  prompt: "Turn this reference into a polished ecommerce hero image.",
  image_urls: [uploaded.dig("data", "url")]
)
```

Uploads support local paths, IO objects, and `Buble::FileUpload`. Path uploads are streamed from disk.

## Video Generation

```ruby
task = client.generations.create(
  model: "gork/grok-imagine-video",
  mode: "text_to_video",
  prompt: "A slow cinematic shot of a futuristic train station at sunrise.",
  duration: "5s",
  resolution: "480p",
  aspect_ratio: "16:9"
)

result = client.generations.wait(
  task.dig("data", "id"),
  interval: 2,
  timeout: 900
)

puts result.dig("data", "result", "videos", 0, "url")
```

Generation request bodies use Buble's flat public API shape. Put model-specific controls in keyword arguments; the SDK serializes those controls at the JSON request root.

Do not send internal Buble fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Apps

```ruby
app = client.apps.retrieve("video-background-remover")
puts app.dig("data", "input_parameters")

task = client.apps.generations.create("video-background-remover", {
  "source_video" => ["https://example.com/source.mp4"],
  "refine_foreground_edges" => true,
  "subject_is_person" => true
})

result = client.apps.generations.wait("video-background-remover", task.dig("data", "id"))
```

Apps are preconfigured workflows. Only send parameter names returned by `client.apps.list` or `client.apps.retrieve(...)`.

## Chat

### OpenAI-Compatible

```ruby
completion = client.chat.completions.create(
  model: "openai/gpt-5.4",
  messages: [
    { role: "user", content: "Write a short launch summary." }
  ],
  max_completion_tokens: 800
)

puts completion.dig("choices", 0, "message", "content")
```

### Streaming

```ruby
client.chat.completions.stream_text(
  model: "openai/gpt-5.4",
  messages: [
    { role: "user", content: "Write one sentence at a time." }
  ]
).each do |text|
  print text
end
```

### Anthropic-Compatible

```ruby
message = client.chat.messages.create(
  model: "openai/gpt-5.4",
  system: "You are concise.",
  messages: [
    { role: "user", content: "Summarize this release." }
  ],
  max_tokens: 800
)
```

### Gemini-Compatible

```ruby
response = client.chat.gemini.generate_content("openai/gpt-5.4", {
  contents: [
    {
      role: "user",
      parts: [
        { text: "Write a short launch summary." }
      ]
    }
  ]
})
```

Gemini streaming uses `stream_generate_content`, not `stream: true` on `generate_content`.

Chat methods preserve protocol-native response shapes as Ruby Hashes with string keys.

## Error Handling

```ruby
begin
  client.generations.retrieve("task_id")
rescue Buble::APIError => error
  warn error.status
  warn error.code
  warn error.message
  warn error.details
end

begin
  client.generations.wait("task_id")
rescue Buble::GenerationFailedError => error
  warn error.task["error"]
end
```

## Development

```bash
cd ruby
bundle install
bundle exec rake test
bundle exec rubocop
gem build buble.gemspec
```

Live smoke test:

```bash
BUBLE_API_KEY=sk_... ruby -Ilib tools/live_smoke.rb
```

The live smoke test calls discovery and chat endpoints only and does not create billable generation tasks.

## Publishing Checklist

RubyGems package identity:

- Gem name: `buble`
- Namespace: `Buble`
- License: MIT
- Homepage: `https://buble.ai/`

Build and publish:

```bash
cd ruby
bundle exec rake test
bundle exec rubocop
gem build buble.gemspec
gem push buble-0.1.0.gem
```

RubyGems versions are immutable. After `0.1.0` is published, fixes must use a new version such as `0.1.1`.
