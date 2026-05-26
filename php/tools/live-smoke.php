<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use Buble\BubleClient;

$client = BubleClient::fromEnv();

$mediaModels = $client->mediaModels()->list();
echo 'media models: ' . count($mediaModels['data'] ?? []) . PHP_EOL;

$apps = $client->apps()->list();
echo 'apps: ' . count($apps['data'] ?? []) . PHP_EOL;

$chatModels = $client->chat()->models()->list();
echo 'chat models: ' . count($chatModels['data'] ?? []) . PHP_EOL;
