# Buble Go SDK

Official Go SDK for the [Buble public API](https://buble.ai/docs).

Use this SDK from server-side Go applications to discover media models, upload source media, create asynchronous image and video generation tasks, run preconfigured Buble app workflows, and call chat models through OpenAI, Anthropic Messages, and Gemini-compatible API formats.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in client-side code.

## Installation

```bash
go get github.com/bublehq/sdks/go
```

## Quick Start

Set your API key:

```bash
export BUBLE_API_KEY="sk_..."
```

The generation examples below create real Buble generation tasks and may consume credits.

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

The client reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

## Configuration

```go
client := buble.NewClient(
	buble.WithAPIKey("sk_..."),
	buble.WithBaseURL("https://buble.ai"),
	buble.WithHTTPClient(http.DefaultClient),
)
```

All API methods accept `context.Context`.

## Discover Media Models

```go
models, err := client.MediaModels.List(ctx, "video")
if err != nil {
	log.Fatal(err)
}

for _, model := range models.Data {
	fmt.Println(model.Model)
}
```

Use media model discovery as the source of truth for model keys, modes, required inputs, and public parameters. New Buble models can become available without a SDK release.

## Upload Files

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

task, err := client.Generations.Create(ctx, &buble.CreateGenerationRequest{
	Model:     "google/nano-banana",
	Mode:      "image_to_image",
	Prompt:    "Turn this reference into a polished ecommerce hero image.",
	ImageURLs: []string{uploaded.Data.URL},
})
```

Uploads support local paths, bytes, and `io.Reader` values. Path uploads are streamed from disk.

## Video Generation

```go
task, err := client.Generations.Create(ctx, &buble.CreateGenerationRequest{
	Model:  "doubao/seedance-2.0-fast",
	Mode:   "text_to_video",
	Prompt: "A slow cinematic shot of a futuristic train station at sunrise.",
	Params: map[string]any{
		"duration":     "8s",
		"resolution":   "720p",
		"aspect_ratio": "16:9",
	},
})
if err != nil {
	log.Fatal(err)
}

result, err := client.Generations.Wait(
	ctx,
	task.Data.ID,
	buble.WithWaitInterval(2*time.Second),
	buble.WithWaitTimeout(10*time.Minute),
)
```

Generation request bodies use Buble's flat public API shape. Put model-specific controls in `Params`; the SDK serializes those controls at the JSON request root.

Do not send internal Buble fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Apps

```go
app, err := client.Apps.Retrieve(ctx, "video-background-remover")
if err != nil {
	log.Fatal(err)
}
fmt.Println(app.Data.InputParameters)

task, err := client.Apps.Generations.Create(ctx, "video-background-remover", map[string]any{
	"source_video":            []string{"https://example.com/source.mp4"},
	"refine_foreground_edges": true,
	"subject_is_person":       true,
})
if err != nil {
	log.Fatal(err)
}

result, err := client.Apps.Generations.Wait(ctx, "video-background-remover", task.Data.ID)
```

Apps are preconfigured workflows. Only send parameter names returned by `Apps.List` or `Apps.Retrieve`.

## Chat

### OpenAI-Compatible

```go
completion, err := client.Chat.Completions.Create(ctx, buble.ChatRequest{
	"model": "openai/gpt-5.5",
	"messages": []any{
		map[string]any{"role": "user", "content": "Write a short launch summary."},
	},
	"reasoning":             true,
	"max_completion_tokens": 800,
})
if err != nil {
	log.Fatal(err)
}
fmt.Println(completion)
```

### Streaming

```go
stream, err := client.Chat.Completions.Stream(ctx, buble.ChatRequest{
	"model": "openai/gpt-5.5",
	"messages": []any{
		map[string]any{"role": "user", "content": "Write one sentence at a time."},
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

### Anthropic-Compatible

```go
message, err := client.Chat.Messages.Create(ctx, buble.ChatRequest{
	"model":  "openai/gpt-5.5",
	"system": "You are concise.",
	"messages": []any{
		map[string]any{"role": "user", "content": "Summarize this release."},
	},
	"max_tokens": 800,
})
```

### Gemini-Compatible

```go
response, err := client.Chat.Gemini.GenerateContent(ctx, "openai/gpt-5.5", buble.ChatRequest{
	"contents": []any{
		map[string]any{
			"role": "user",
			"parts": []any{
				map[string]any{"text": "Write a short launch summary."},
			},
		},
	},
})
```

Gemini streaming uses `StreamGenerateContent`, not `stream: true` on `GenerateContent`.

## Error Handling

```go
task, err := client.Generations.Create(ctx, &buble.CreateGenerationRequest{
	Model: "missing/model",
	Mode:  "text_to_image",
})
if err != nil {
	var apiErr *buble.APIError
	if errors.As(err, &apiErr) {
		fmt.Println(apiErr.StatusCode, apiErr.Code, apiErr.Message, apiErr.Details)
	}
}
_ = task

_, err = client.Generations.Wait(ctx, "task_id")
if err != nil {
	var generationErr *buble.GenerationFailedError
	if errors.As(err, &generationErr) {
		fmt.Println(generationErr.Task)
	}
}
```

## Development

```bash
go test ./...
go vet ./...
```

Live smoke test:

```bash
BUBLE_API_KEY=sk_... go run ./cmd/live-smoke
```

The live smoke test calls discovery and error-handling paths and is intended to avoid creating billable generation tasks.

## Publishing

This SDK is a Go module in a monorepo subdirectory:

```txt
module github.com/bublehq/sdks/go
```

Release tags must include the module subdirectory prefix:

```bash
git tag go/v0.1.0
git push origin go/v0.1.0
GOPROXY=proxy.golang.org go list -m github.com/bublehq/sdks/go@v0.1.0
```

After the Go proxy indexes the module, documentation will appear at:

```txt
https://pkg.go.dev/github.com/bublehq/sdks/go
```

## License

MIT.
