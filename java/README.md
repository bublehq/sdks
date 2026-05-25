# Buble Java SDK

Official Java SDK for the [Buble public API](https://buble.ai/docs).

Use this SDK from server-side Java applications to discover media models, upload
source media, create asynchronous image and video generation tasks, run
preconfigured Buble app workflows, and call chat models through OpenAI,
Anthropic Messages, and Gemini-compatible API formats.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in browser, mobile,
or other client-side code.

## Installation

Maven:

```xml
<dependency>
  <groupId>ai.buble</groupId>
  <artifactId>buble-sdk</artifactId>
  <version>0.1.0</version>
</dependency>
```

Gradle:

```gradle
implementation("ai.buble:buble-sdk:0.1.0")
```

The package is designed for Java 11+.

## Quick Start

Set your API key:

```bash
export BUBLE_API_KEY="sk_..."
```

The generation examples below create real Buble generation tasks and may consume credits.

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

The client reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

## Configuration

```java
BubleClient client = BubleClient.builder()
        .apiKey("sk_...")
        .baseUrl("https://buble.ai")
        .timeout(Duration.ofSeconds(60))
        .build();
```

## Discover Media Models

```java
Envelope<List<MediaModel>> models = client.mediaModels().list("video");
for (MediaModel model : models.getData()) {
    System.out.println(model.getModel());
}
```

Use media model discovery as the source of truth for model keys, modes, required
inputs, and public parameters. New Buble models can become available without an
SDK release.

## Upload Files

```java
Envelope<UploadedFile> uploaded = client.files().upload(
        FileUpload.fromPath(Path.of("reference.png")),
        UploadOptions.builder()
                .fileType("image")
                .model("google/nano-banana")
                .mode("image_to_image")
                .build());

Envelope<GenerationTask> task = client.generations().create(
        CreateGenerationRequest.builder()
                .model("google/nano-banana")
                .mode("image_to_image")
                .prompt("Turn this reference into a polished ecommerce hero image.")
                .imageUrls(List.of(uploaded.getData().getUrl()))
                .build());
```

Uploads support local paths, bytes, and `InputStream` values.

## Video Generation

```java
Envelope<GenerationTask> task = client.generations().create(
        CreateGenerationRequest.builder()
                .model("doubao/seedance-2.0-fast")
                .mode("text_to_video")
                .prompt("A slow cinematic shot of a futuristic train station at sunrise.")
                .param("duration", "8s")
                .param("resolution", "720p")
                .param("aspect_ratio", "16:9")
                .build());

Envelope<GenerationTask> result = client.generations().wait(
        task.getData().getId(),
        WaitOptions.builder()
                .interval(Duration.ofSeconds(2))
                .timeout(Duration.ofMinutes(10))
                .build());
```

Generation request bodies use Buble's flat public API shape. Put
model-specific controls in `param(...)`; the SDK serializes those controls at
the JSON request root.

Do not send internal Buble fields such as `input`, `options`, `scene`,
`sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Apps

```java
Envelope<PublicApp> app = client.apps().retrieve("video-background-remover");
System.out.println(app.getData().getInputParameters());

Envelope<AppGenerationTask> task = client.apps().generations().create(
        "video-background-remover",
        Map.of(
                "source_video", List.of("https://example.com/source.mp4"),
                "refine_foreground_edges", true,
                "subject_is_person", true
        ));

Envelope<AppGenerationTask> result = client.apps().generations().wait(
        "video-background-remover",
        task.getData().getId());
```

Apps are preconfigured workflows. Only send parameter names returned by
`client.apps().list()` or `client.apps().retrieve(...)`.

## Chat

### OpenAI-Compatible

```java
Map<String, JsonNode> completion = client.chat().completions().create(Map.of(
        "model", "openai/gpt-5.5",
        "messages", List.of(Map.of("role", "user", "content", "Write a short launch summary.")),
        "max_completion_tokens", 800
));
```

### Streaming

```java
try (BubleStream stream = client.chat().completions().stream(Map.of(
        "model", "openai/gpt-5.5",
        "messages", List.of(Map.of("role", "user", "content", "Write one sentence at a time."))
))) {
    while (stream.next()) {
        System.out.print(stream.text());
    }
}
```

### Anthropic-Compatible

```java
Map<String, JsonNode> message = client.chat().messages().create(Map.of(
        "model", "openai/gpt-5.5",
        "system", "You are concise.",
        "messages", List.of(Map.of("role", "user", "content", "Summarize this release.")),
        "max_tokens", 800
));
```

### Gemini-Compatible

```java
Map<String, JsonNode> response = client.chat().gemini().generateContent(
        "google/gemini-2.5-flash",
        Map.of("contents", List.of(
                Map.of("role", "user", "parts", List.of(Map.of("text", "Write one concise sentence.")))
        )));
```

Chat methods preserve protocol-native response shapes as `Map<String, JsonNode>`.

## Error Handling

```java
try {
    client.generations().retrieve("task_id");
} catch (BubleApiException error) {
    System.err.println(error.getStatusCode());
    System.err.println(error.getCode());
    System.err.println(error.getMessage());
}
```

Common SDK exceptions:

- `BubleApiException` for non-2xx API responses.
- `BubleTimeoutException` for request or polling timeouts.
- `UnsupportedGenerationFieldException` for known internal generation fields.
- `GenerationFailedException` and `GenerationCanceledException` from wait helpers.

## Development

```bash
cd java
mvn test
mvn verify
```

## Publishing

The Java SDK is configured for Maven Central publication. MVNRepository is an
indexing site; it will show the artifact after Maven Central is published and
indexed.

Before the first release:

1. Verify the `ai.buble` namespace in Sonatype Central Portal.
2. Configure a Central Portal token in `~/.m2/settings.xml` with server id `central`.
3. Configure GPG signing for release artifacts.
4. Run local verification:

```bash
mvn clean verify
```

Release deploy:

```bash
mvn -P release clean deploy
```

The Central publishing plugin is configured with `autoPublish=false`, so the
deployment can be reviewed in Central Portal before manual publication.

Maven Central versions are immutable. If `0.1.0` is published, fixes must use a
new version such as `0.1.1`.

## License

MIT. See [LICENSE](LICENSE).
