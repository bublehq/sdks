# Buble Java SDK Technical Design

The Java SDK mirrors the public Buble API and follows the same design model as
the npm, Python, and Go SDKs in this monorepo.

## Goals

- Keep API keys on the server.
- Preserve Buble media, file, and app response envelopes as `Envelope<T>`.
- Preserve protocol-native chat response shapes as `Map<String, JsonNode>`.
- Keep media generation requests compatible with Buble's flat public API shape.
- Support new Buble models, modes, app inputs, and chat capabilities without an
  SDK release by exposing discovery APIs and flexible parameter maps.
- Use Java-standard APIs where practical.

## Runtime Choices

- Java 11+ for `java.net.http.HttpClient`.
- Maven for build and Maven Central publishing.
- Jackson for JSON serialization and deserialization.
- No Lombok and no third-party HTTP client dependency.

## Public Package

The Maven coordinates are:

```txt
groupId: ai.buble
artifactId: buble-sdk
package: ai.buble.sdk
module: ai.buble.sdk
```

The preferred import pattern is:

```java
import ai.buble.sdk.BubleClient;
```

## Resource Model

`BubleClient` exposes resource services:

- `client.mediaModels()`
- `client.files()`
- `client.generations()`
- `client.apps()`
- `client.chat()`

This matches the conceptual layout of the other SDKs while using Java naming
conventions.

## Generation Requests

`CreateGenerationRequest` has stable fields for common Buble inputs and a
flexible `param(key, value)` API for model-specific controls:

```java
CreateGenerationRequest.builder()
    .model("google/nano-banana")
    .mode("text_to_image")
    .prompt("A product photo")
    .param("aspect_ratio", "1:1")
    .build();
```

The request is serialized as a flat object. It never serializes a nested
`params` object.

The SDK rejects known internal fields that are not accepted by the public
generation API:

```txt
input
options
scene
sub_mode_id
subModeId
provider
mediaType
media_type
images
image_input
video_input
audio_input
```

## Chat Responses

The OpenAI-compatible, Anthropic Messages-compatible, and Gemini-compatible
methods return `Map<String, JsonNode>` so provider-specific fields remain
available without SDK changes.

Streaming methods return `BubleStream`, which exposes both raw SSE events and
protocol-aware text extraction through `text()`.

## Publishing

`pom.xml` is configured for Maven Central publication through Sonatype Central
Portal using `central-publishing-maven-plugin`.

Release artifacts include:

- main JAR
- sources JAR
- Javadoc JAR
- signed artifacts when the `release` profile is used
- Maven Central metadata: name, description, license, SCM, and developer fields

The `ai.buble` namespace must be verified in Central Portal before the first
release can be published.
