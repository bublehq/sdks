# Buble SDK for .NET

Official .NET SDK for [Buble](https://buble.ai), built for the [Buble public API](https://buble.ai/docs).

Use this SDK from server-side .NET applications to discover media models, upload source media, create asynchronous image and video generation tasks, run preconfigured Buble app workflows, and call chat models through OpenAI, Anthropic Messages, and Gemini-compatible API formats.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in browser, mobile, or other client-side code.

## Installation

After publication to NuGet.org:

```bash
dotnet add package Buble.SDK --version 0.1.2
```

Package Manager:

```powershell
Install-Package Buble.SDK -Version 0.1.2
```

The package targets `netstandard2.0` and `net8.0`.

## Quick Start

Set your API key:

```bash
export BUBLE_API_KEY="sk_..."
```

The generation examples below create real Buble generation tasks and may consume credits.

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

The client reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

## Configuration

```csharp
using var client = new BubleClient(new BubleClientOptions
{
    ApiKey = "sk_...",
    BaseUrl = "https://buble.ai",
    Timeout = TimeSpan.FromSeconds(60)
});
```

You may pass an externally managed `HttpClient` through `BubleClientOptions.HttpClient`.

## Discover Media Models

```csharp
var models = await client.MediaModels.ListAsync(mediaType: "video");

if (models?.Data is not null)
{
    foreach (var model in models.Data)
    {
        Console.WriteLine(model.Model);
    }
}
```

Use media model discovery as the source of truth for model keys, modes, required inputs, and public parameters. New Buble models can become available without an SDK release.

## Upload Files

```csharp
using Buble.Sdk.Files;
using Buble.Sdk.Generations;

var uploaded = await client.Files.UploadAsync(
    FileUpload.FromPath("reference.png", "image/png"),
    new UploadOptions
    {
        FileType = "image",
        Model = "google/nano-banana",
        Mode = "image_to_image"
    });

var task = await client.Generations.CreateAsync(new CreateGenerationRequest
{
    Model = "google/nano-banana",
    Mode = "image_to_image",
    Prompt = "Turn this reference into a polished ecommerce hero image.",
    ImageUrls = new[] { uploaded!.Data!.Url! }
});
```

Uploads support local paths, byte arrays, and stream factories. Path uploads are streamed from disk.

## Video Generation

```csharp
var task = await client.Generations.CreateAsync(new CreateGenerationRequest
{
    Model = "doubao/seedance-2.0-fast",
    Mode = "text_to_video",
    Prompt = "A slow cinematic shot of a futuristic train station at sunrise."
}.WithParam("duration", "8s")
 .WithParam("resolution", "720p")
 .WithParam("aspect_ratio", "16:9"));

var result = await client.Generations.WaitAsync(
    task!.Data!.Id!,
    new WaitOptions
    {
        Interval = TimeSpan.FromSeconds(2),
        Timeout = TimeSpan.FromMinutes(10)
    });
```

Generation request bodies use Buble's flat public API shape. Put model-specific controls in `WithParam(...)`; the SDK serializes those controls at the JSON request root.

Do not send internal Buble fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Apps

```csharp
var app = await client.Apps.RetrieveAsync("video-background-remover");
Console.WriteLine(app?.Data?.InputParameters);

var task = await client.Apps.Generations.CreateAsync(
    "video-background-remover",
    new Dictionary<string, object?>
    {
        ["source_video"] = new[] { "https://example.com/source.mp4" },
        ["refine_foreground_edges"] = true,
        ["subject_is_person"] = true
    });

var result = await client.Apps.Generations.WaitAsync(
    "video-background-remover",
    task!.Data!.Id!);
```

Apps are preconfigured workflows. Only send parameter names returned by `client.Apps.ListAsync()` or `client.Apps.RetrieveAsync(...)`.

## Chat

### OpenAI-Compatible

```csharp
var completion = await client.Chat.Completions.CreateAsync(new Dictionary<string, object?>
{
    ["model"] = "openai/gpt-5.5",
    ["messages"] = new[]
    {
        new Dictionary<string, object?>
        {
            ["role"] = "user",
            ["content"] = "Write a short launch summary."
        }
    },
    ["max_completion_tokens"] = 800
});

Console.WriteLine(completion?["choices"]?[0]?["message"]?["content"]?.GetValue<string>());
```

### Streaming

```csharp
await foreach (var text in client.Chat.Completions.StreamTextAsync(new Dictionary<string, object?>
{
    ["model"] = "openai/gpt-5.5",
    ["messages"] = new[]
    {
        new Dictionary<string, object?>
        {
            ["role"] = "user",
            ["content"] = "Write one sentence at a time."
        }
    }
}))
{
    Console.Write(text);
}
```

### Anthropic-Compatible

```csharp
var message = await client.Chat.Messages.CreateAsync(new Dictionary<string, object?>
{
    ["model"] = "openai/gpt-5.5",
    ["system"] = "You are concise.",
    ["messages"] = new[]
    {
        new Dictionary<string, object?>
        {
            ["role"] = "user",
            ["content"] = "Summarize this release."
        }
    },
    ["max_tokens"] = 800
});
```

### Gemini-Compatible

```csharp
using System.Text.Json.Nodes;

var response = await client.Chat.Gemini.GenerateContentAsync("openai/gpt-5.5", new JsonObject
{
    ["contents"] = new JsonArray
    {
        new JsonObject
        {
            ["role"] = "user",
            ["parts"] = new JsonArray(new JsonObject { ["text"] = "Write one concise sentence." })
        }
    }
});
```

Gemini streaming uses `StreamGenerateContentAsync`, not `stream: true` on `GenerateContentAsync`.

Chat methods preserve protocol-native response shapes as `JsonObject`.

## Error Handling

```csharp
try
{
    await client.Generations.RetrieveAsync("task_id");
}
catch (BubleApiException error)
{
    Console.Error.WriteLine(error.StatusCode);
    Console.Error.WriteLine(error.Code);
    Console.Error.WriteLine(error.Message);
    Console.Error.WriteLine(error.Details);
}

try
{
    await client.Generations.WaitAsync("task_id");
}
catch (GenerationFailedException error)
{
    Console.Error.WriteLine(error.Task.Error?.Message);
}
```

## Development

```bash
cd dotnet
dotnet restore
dotnet test -c Release
dotnet pack src/Buble.Sdk/Buble.Sdk.csproj -c Release -o artifacts
```

Live smoke test:

```bash
BUBLE_API_KEY=sk_... dotnet run --project tools/Buble.Sdk.LiveSmoke -c Release
```

The live smoke test calls discovery endpoints only and does not create billable generation tasks.

## Publishing Checklist

NuGet package identity:

- Package ID: `Buble.SDK`
- Namespace: `Buble.Sdk`
- Version: `0.1.2`
- License: MIT

Before publishing, ensure the package ID is available or owned by the Buble NuGet.org account.

```bash
cd dotnet
dotnet restore
dotnet test -c Release
dotnet pack src/Buble.Sdk/Buble.Sdk.csproj -c Release -o artifacts
dotnet nuget push artifacts/Buble.SDK.0.1.2.nupkg \
  --api-key "$NUGET_API_KEY" \
  --source https://api.nuget.org/v3/index.json
```

NuGet.org indexes the package after upload. The package README is included through `PackageReadmeFile`, and symbols are produced as `.snupkg` for debugging support. If your NuGet client does not publish the symbol package together with the main package, push `artifacts/Buble.SDK.0.1.2.snupkg` to the same source.
