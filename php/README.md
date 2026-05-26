# Buble SDK for PHP

Official PHP SDK for [Buble](https://buble.ai/), built for the [Buble public API](https://buble.ai/docs).

Use this SDK from server-side PHP applications to discover media models, upload source media, create asynchronous image and video generation tasks, run preconfigured Buble app workflows, and call chat models through OpenAI, Anthropic Messages, and Gemini-compatible API formats.

Keep API keys on the server. Do not expose `BUBLE_API_KEY` in browser, mobile, or other client-side code.

## Installation

After publication to Packagist:

```bash
composer require buble/sdk
```

The package requires PHP 8.2+, `ext-curl`, and `ext-json`.

## Quick Start

Set your API key:

```bash
export BUBLE_API_KEY="sk_..."
```

The generation examples below create real Buble generation tasks and may consume credits.

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

The client reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment when omitted.

## Configuration

```php
use Buble\BubleClient;
use Buble\BubleClientOptions;

$client = new BubleClient(new BubleClientOptions(
    apiKey: 'sk_...',
    baseUrl: 'https://buble.ai',
    timeout: 60.0,
));
```

## Discover Media Models

```php
$models = $client->mediaModels()->list(mediaType: 'video');

foreach ($models['data'] as $model) {
    echo $model['model'] . PHP_EOL;
}
```

Use media model discovery as the source of truth for model keys, modes, required inputs, and public parameters. New Buble models can become available without an SDK release.

## Upload Files

```php
use Buble\Files\FileUpload;
use Buble\Files\UploadOptions;
use Buble\Generations\CreateGenerationRequest;

$uploaded = $client->files()->upload(
    FileUpload::fromPath('reference.png', 'image/png'),
    new UploadOptions(
        fileType: 'image',
        model: 'google/nano-banana',
        mode: 'image_to_image',
    ),
);

$task = $client->generations()->create(new CreateGenerationRequest(
    model: 'google/nano-banana',
    mode: 'image_to_image',
    prompt: 'Turn this reference into a polished ecommerce hero image.',
    imageUrls: [$uploaded['data']['url']],
));
```

Uploads support local paths, strings of bytes, and PHP stream resources. Path uploads are streamed from disk by cURL.

## Video Generation

```php
use Buble\WaitOptions;

$task = $client->generations()->create(
    CreateGenerationRequest::make(
        model: 'doubao/seedance-2.0-fast',
        mode: 'text_to_video',
        prompt: 'A slow cinematic shot of a futuristic train station at sunrise.',
    )->withParam('duration', '8s')
     ->withParam('resolution', '720p')
     ->withParam('aspect_ratio', '16:9')
);

$result = $client->generations()->wait(
    $task['data']['id'],
    new WaitOptions(interval: 2.0, timeout: 600.0),
);
```

Generation request bodies use Buble's flat public API shape. Put model-specific controls in `withParam(...)`; the SDK serializes those controls at the JSON request root.

Do not send internal Buble fields such as `input`, `options`, `scene`, `sub_mode_id`, `provider`, `mediaType`, or `media_type`.

## Apps

```php
$app = $client->apps()->retrieve('video-background-remover');
print_r($app['data']['input_parameters']);

$task = $client->apps()->generations()->create('video-background-remover', [
    'source_video' => ['https://example.com/source.mp4'],
    'refine_foreground_edges' => true,
    'subject_is_person' => true,
]);

$result = $client->apps()->generations()->wait('video-background-remover', $task['data']['id']);
```

Apps are preconfigured workflows. Only send parameter names returned by `apps()->list()` or `apps()->retrieve(...)`.

## Chat

### OpenAI-Compatible

```php
$completion = $client->chat()->completions()->create([
    'model' => 'openai/gpt-5.5',
    'messages' => [
        ['role' => 'user', 'content' => 'Write a short launch summary.'],
    ],
    'max_completion_tokens' => 800,
]);

echo $completion['choices'][0]['message']['content'];
```

### Streaming

```php
foreach ($client->chat()->completions()->streamText([
    'model' => 'openai/gpt-5.5',
    'messages' => [
        ['role' => 'user', 'content' => 'Write one sentence at a time.'],
    ],
]) as $text) {
    echo $text;
}
```

### Anthropic-Compatible

```php
$message = $client->chat()->messages()->create([
    'model' => 'openai/gpt-5.5',
    'system' => 'You are concise.',
    'messages' => [
        ['role' => 'user', 'content' => 'Summarize this release.'],
    ],
    'max_tokens' => 800,
]);
```

### Gemini-Compatible

```php
$response = $client->chat()->gemini()->generateContent('openai/gpt-5.5', [
    'contents' => [
        [
            'role' => 'user',
            'parts' => [
                ['text' => 'Write a short launch summary.'],
            ],
        ],
    ],
]);
```

Gemini streaming uses `streamGenerateContent`, not `stream: true` on `generateContent`.

Chat methods preserve protocol-native response shapes as associative arrays.

## Error Handling

```php
use Buble\Exception\ApiException;
use Buble\Exception\GenerationFailedException;

try {
    $client->generations()->retrieve('task_id');
} catch (ApiException $error) {
    echo $error->statusCode . PHP_EOL;
    echo $error->apiCode . PHP_EOL;
    echo $error->getMessage() . PHP_EOL;
    print_r($error->details);
}

try {
    $client->generations()->wait('task_id');
} catch (GenerationFailedException $error) {
    print_r($error->task['error'] ?? null);
}
```

## Development

```bash
cd php
composer validate --strict
composer install
composer test
composer analyse
composer cs
```

Live smoke test:

```bash
BUBLE_API_KEY=sk_... php tools/live-smoke.php
```

The live smoke test calls discovery endpoints only and does not create billable generation tasks.

## Publishing Checklist

Packagist package identity:

- Package name: `buble/sdk`
- Namespace: `Buble\`
- License: MIT
- Homepage: `https://buble.ai/`

Because this repository is a multi-language monorepo, publish the PHP SDK through a PHP-only split repository rather than submitting the monorepo root to Packagist:

```bash
git subtree split --prefix=php -b php-release
git push git@github.com:bublehq/php-sdk.git php-release:main --force-with-lease
```

Create and push a release tag in the PHP-only repository:

```bash
git tag v0.1.0
git push origin v0.1.0
```

Submit the PHP-only repository to Packagist:

```txt
https://github.com/bublehq/php-sdk
```

Configure the GitHub/Packagist hook so new tags are indexed automatically. Composer package versions are immutable once tagged; fixes after `v0.1.0` should use a new tag such as `v0.1.1`.
