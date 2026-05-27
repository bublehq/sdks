# Buble SDK for Dart and Flutter

Official Dart and Flutter SDK for [Buble](https://buble.ai/), built for the [Buble public API](https://buble.ai/docs).

Use this SDK from Dart or Flutter applications to discover media models, upload source media, create asynchronous image and video generation tasks, run preconfigured Buble app workflows, and call chat models through OpenAI, Anthropic Messages, and Gemini-compatible API formats.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in public Flutter mobile binaries, web apps, or other client-side code unless requests are mediated through your own backend.

## Installation

After publication to pub.dev:

```bash
dart pub add buble
```

For Flutter projects:

```bash
flutter pub add buble
```

The package requires Dart 3.4+ and uses `package:http`.

## Quick Start

Set your API key for Dart CLI or server-side usage:

```bash
export BUBLE_API_KEY="sk_..."
```

The generation examples below create real Buble generation tasks and may consume credits.

```dart
import 'package:buble/buble.dart';

Future<void> main() async {
  final client = BubleClient.fromEnvironment();

  final task = await client.generations.create(
    CreateGenerationRequest(
      model: 'google/nano-banana',
      mode: 'text_to_image',
      prompt: 'A cinematic product photo of a matte black espresso cup',
    ).withParam('aspect_ratio', '1:1').withParam('output_format', 'png'),
  );

  final result = await client.generations.wait(task.data.id);
  print(result.data.result?.images.firstOrNull?.url);
}
```

The client reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted on Dart IO platforms.

## Configuration

```dart
final client = BubleClient(
  apiKey: 'sk_...',
  baseUrl: Uri.parse('https://buble.ai'),
  timeout: const Duration(seconds: 60),
  headers: {'X-Request-Id': 'request-id'},
);
```

You may pass a custom `package:http` client for tests or managed networking:

```dart
final client = BubleClient(apiKey: 'sk_...', httpClient: customClient);
```

## Discover Media Models

```dart
final models = await client.mediaModels.list(mediaType: 'video');

for (final model in models.data) {
  print(model.model);
}
```

Use media model discovery as the source of truth for model keys, modes, required inputs, and public parameters. New Buble models can become available without an SDK release.

## Upload Files

```dart
final uploaded = await client.files.upload(
  FileUpload.fromPath('reference.png', contentType: 'image/png'),
  options: const UploadOptions(
    fileType: 'image',
    model: 'google/nano-banana',
    mode: 'image_to_image',
  ),
);

final task = await client.generations.create(
  CreateGenerationRequest(
    model: 'google/nano-banana',
    mode: 'image_to_image',
    prompt: 'Turn this reference into a polished ecommerce hero image.',
    imageUrls: [uploaded.data.url.toString()],
  ),
);
```

Uploads support local paths on Dart IO platforms, plus byte buffers and streams for cross-platform use. If `model` and `mode` are provided, Buble validates the upload against that model mode.

## Video Generation

```dart
final task = await client.generations.create(
  CreateGenerationRequest(
    model: 'gork/grok-imagine-video',
    mode: 'text_to_video',
    prompt: 'A slow cinematic shot of a futuristic train station at sunrise.',
  )
      .withParam('duration', '5s')
      .withParam('resolution', '480p')
      .withParam('aspect_ratio', '16:9'),
);

final result = await client.generations.wait(
  task.data.id,
  options: const WaitOptions(
    interval: Duration(seconds: 2),
    timeout: Duration(minutes: 15),
  ),
);
```

Generation request bodies use Buble's flat public API shape. Put model-specific controls in `withParam(...)`; the SDK serializes those controls at the JSON request root.

Do not send internal Buble fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Apps

```dart
final app = await client.apps.retrieve('video-background-remover');
print(app.data.inputParameters);

final task = await client.apps.generations.create('video-background-remover', {
  'source_video': ['https://example.com/source.mp4'],
  'refine_foreground_edges': true,
  'subject_is_person': true,
});

final result = await client.apps.generations.wait(
  'video-background-remover',
  task.data.id,
);
```

Apps are preconfigured workflows. Only send parameter names returned by `client.apps.list(...)` or `client.apps.retrieve(...)`.

## Chat

### OpenAI-Compatible

```dart
final completion = await client.chat.completions.create({
  'model': 'openai/gpt-5.4',
  'messages': [
    {'role': 'user', 'content': 'Write a short launch summary.'},
  ],
  'max_completion_tokens': 800,
});
```

### Streaming

```dart
final stream = await client.chat.completions.streamText({
  'model': 'openai/gpt-5.4',
  'messages': [
    {'role': 'user', 'content': 'Write one sentence at a time.'},
  ],
});

await for (final text in stream) {
  print(text);
}
```

### Anthropic-Compatible

```dart
final message = await client.chat.messages.create({
  'model': 'openai/gpt-5.4',
  'system': 'You are concise.',
  'messages': [
    {'role': 'user', 'content': 'Summarize this release.'},
  ],
  'max_tokens': 800,
});
```

### Gemini-Compatible

```dart
final response = await client.chat.gemini.generateContent('openai/gpt-5.4', {
  'contents': [
    {
      'role': 'user',
      'parts': [
        {'text': 'Write a short launch summary.'},
      ],
    },
  ],
});
```

Gemini streaming uses `streamGenerateContent`, not `stream: true` on `generateContent`.

Chat methods preserve protocol-native response shapes as `Map<String, Object?>`.

## Error Handling

```dart
try {
  await client.generations.retrieve('task_id');
} on BubleApiException catch (error) {
  print(error.statusCode);
  print(error.code);
  print(error.message);
  print(error.details);
}

try {
  await client.generations.wait('task_id');
} on GenerationFailedException catch (error) {
  print(error.task.error?.message);
}
```

## Live Smoke Test

The live smoke command calls discovery and chat paths. Run it only with a valid API key:

```bash
cd flutter
BUBLE_API_KEY=sk_... dart run tool/live_smoke.dart
```

## Publishing

The first pub.dev release must be published manually:

```bash
cd flutter
dart pub get
dart format --set-exit-if-changed .
dart analyze
dart test
dart pub publish --dry-run
dart pub publish
```

After the first release exists on pub.dev, configure automated publishing for package `buble` with:

- Repository: `bublehq/sdks`
- Tag pattern: `flutter-v{{version}}`

Then publish future versions by updating `pubspec.yaml` and pushing a monorepo tag:

```bash
git tag flutter-v0.1.1
git push origin flutter-v0.1.1
```

pub.dev versions are immutable. Publish fixes with a new version.

## License

MIT. See `LICENSE`.
