<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use Buble\BubleClient;

$client = BubleClient::fromEnv();

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

echo $response['candidates'][0]['content']['parts'][0]['text'] . PHP_EOL;
