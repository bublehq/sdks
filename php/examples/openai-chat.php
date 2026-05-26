<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use Buble\BubleClient;

$client = BubleClient::fromEnv();

$completion = $client->chat()->completions()->create([
    'model' => 'openai/gpt-5.5',
    'messages' => [
        ['role' => 'user', 'content' => 'Write a short launch summary.'],
    ],
    'max_completion_tokens' => 800,
]);

echo $completion['choices'][0]['message']['content'] . PHP_EOL;
