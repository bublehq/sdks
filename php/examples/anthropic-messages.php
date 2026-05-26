<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use Buble\BubleClient;

$client = BubleClient::fromEnv();

$message = $client->chat()->messages()->create([
    'model' => 'openai/gpt-5.5',
    'system' => 'You are concise.',
    'messages' => [
        ['role' => 'user', 'content' => 'Summarize this release.'],
    ],
    'max_tokens' => 800,
]);

echo $message['content'][0]['text'] . PHP_EOL;
