# Buble SDK for Elixir

Official Elixir SDK for [Buble](https://buble.ai/), built for the [Buble public API](https://buble.ai/docs).

Use this SDK from server-side Elixir applications to discover media models, upload source media, create asynchronous image and video generation tasks, run preconfigured Buble app workflows, and call chat models through OpenAI, Anthropic Messages, and Gemini-compatible API formats.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in browser, mobile, or other client-side code.

## Installation

Add `buble` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:buble, "~> 0.1.0"}
  ]
end
```

Then run:

```sh
mix deps.get
```

## Quick Start

Set your API key:

```sh
export BUBLE_API_KEY="sk_..."
```

The generation examples below create real Buble generation tasks and may consume credits.

```elixir
client = Buble.Client.new!()

{:ok, task} =
  Buble.Generations.create(client, %{
    model: "nano-banana",
    prompt: "A cinematic studio product photo of a translucent blue cube"
  })

id = task["data"]["id"]
{:ok, result} = Buble.Generations.wait(client, id)

image_url = result["data"]["result"]["images"] |> List.first() |> Map.fetch!("url")
IO.puts(image_url)
```

## Client Configuration

```elixir
client =
  Buble.Client.new!(
    api_key: "sk_...",
    base_url: "https://buble.ai",
    timeout: 120_000,
    headers: [{"x-request-source", "my-app"}]
  )
```

`Buble.Client.new!/1` also reads:

- `BUBLE_API_KEY`
- `BUBLE_BASE_URL`

Use non-bang functions when you want explicit error tuples:

```elixir
case Buble.Client.new() do
  {:ok, client} -> client
  {:error, %Buble.Error{} = error} -> raise error
end
```

## Media Models

Use media model discovery as the source of truth for model keys, modes, required inputs, and public parameters. New Buble models can become available without an SDK release.

```elixir
{:ok, models} = Buble.MediaModels.list(client, media_type: "image")
```

## File Uploads

Uploads support local paths and in-memory binaries. If `model` and `mode` are provided, Buble validates the upload against that model mode.

```elixir
{:ok, upload} =
  Buble.Files.upload(
    client,
    {:path, "reference.png"},
    file_type: "image",
    model: "nano-banana"
  )

image_url = upload["data"]["url"]
```

Binary upload:

```elixir
{:ok, upload} =
  Buble.Files.upload(
    client,
    {:binary, png_bytes, filename: "reference.png", content_type: "image/png"},
    file_type: "image"
  )
```

## Generations

Generation request bodies use Buble's flat public API shape. Put model-specific controls in the request map; the SDK serializes those controls at the JSON request root.

Do not send internal Buble fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

```elixir
{:ok, task} =
  Buble.Generations.create(client, %{
    model: "grok-imagine-video",
    mode: "text_to_video",
    prompt: "A neon city street at night, cinematic camera movement",
    aspect_ratio: "16:9"
  })

{:ok, result} = Buble.Generations.wait(client, task["data"]["id"])
```

You can also pass dynamic model parameters under `:params`; they are merged into the request root:

```elixir
{:ok, task} =
  Buble.Generations.create(client, %{
    model: "nano-banana",
    prompt: "A clean vector-style logo mark",
    params: %{
      aspect_ratio: "1:1"
    }
  })
```

Polling options:

```elixir
Buble.Generations.wait(client, task["data"]["id"],
  interval: 2_000,
  timeout: 600_000,
  throw_on_failed: true,
  throw_on_canceled: true
)
```

## Apps

```elixir
{:ok, apps} = Buble.Apps.list(client)
{:ok, app} = Buble.Apps.retrieve(client, "video-background-remover")

{:ok, task} =
  Buble.Apps.Generations.create(client, "video-background-remover", %{
    video_url: "https://example.com/input.mp4"
  })

{:ok, result} =
  Buble.Apps.Generations.wait(client, "video-background-remover", task["data"]["id"])
```

## Chat

OpenAI-compatible chat completions:

```elixir
{:ok, response} =
  Buble.Chat.Completions.create(client, %{
    model: "chatgpt-5-4",
    messages: [
      %{role: "user", content: "Write one sentence about Elixir."}
    ]
  })
```

Streaming text:

```elixir
{:ok, stream} =
  Buble.Chat.Completions.stream_text(client, %{
    model: "chatgpt-5-4",
    messages: [%{role: "user", content: "Count to three."}]
  })

Enum.each(stream, &IO.write/1)
```

Anthropic Messages-compatible calls:

```elixir
{:ok, response} =
  Buble.Chat.Messages.create(client, %{
    model: "claude-sonnet",
    max_tokens: 128,
    messages: [%{role: "user", content: "Hello"}]
  })
```

Gemini-compatible calls:

```elixir
{:ok, response} =
  Buble.Chat.Gemini.generate_content(client, "gemini-3-pro", %{
    contents: [
      %{role: "user", parts: [%{text: "Hello"}]}
    ]
  })
```

## Errors

Non-bang functions return `{:ok, value}` or `{:error, %Buble.Error{}}`.

```elixir
case Buble.Generations.create(client, %{model: "nano-banana", prompt: "A fox"}) do
  {:ok, task} ->
    task

  {:error, %Buble.Error{type: :api, status: status, message: message}} ->
    IO.puts("Buble API error #{status}: #{message}")
end
```

Bang functions such as `Buble.Client.new!/1`, `Buble.Generations.create!/2`, and `Buble.Generations.wait!/3` raise `Buble.Error`.

## Testing

```sh
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix docs
mix hex.build
```

## Publishing

The package is published to Hex.pm as `buble` and documented on HexDocs:

- Hex.pm: <https://hex.pm/packages/buble>
- HexDocs: <https://hexdocs.pm/buble>

Publish from `elixir/`:

```sh
mix hex.publish
```

Use `mix hex.publish --dry-run` after authenticating with Hex.pm when you want
the same local package checks without uploading a release.

Hex package versions are immutable for normal release workflows. After `0.1.0` is published, fixes should use a new version such as `0.1.1`.
