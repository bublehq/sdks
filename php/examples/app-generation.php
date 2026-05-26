<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use Buble\BubleClient;

$client = BubleClient::fromEnv();

$app = $client->apps()->retrieve('video-background-remover');
echo $app['data']['name'] . PHP_EOL;

$task = $client->apps()->generations()->create('video-background-remover', [
    'source_video' => ['https://example.com/source.mp4'],
    'refine_foreground_edges' => true,
    'subject_is_person' => true,
]);

$result = $client->apps()->generations()->wait('video-background-remover', $task['data']['id']);
echo $result['data']['result']['videos'][0]['url'] . PHP_EOL;
