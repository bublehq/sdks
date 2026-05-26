<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use Buble\BubleClient;
use Buble\Generations\CreateGenerationRequest;
use Buble\WaitOptions;

$client = BubleClient::fromEnv();

$task = $client->generations()->create(
    CreateGenerationRequest::make(
        model: 'doubao/seedance-2.0-fast',
        mode: 'text_to_video',
        prompt: 'A slow cinematic shot of a futuristic train station at sunrise.',
    )->withParam('duration', '8s')
     ->withParam('resolution', '720p')
     ->withParam('aspect_ratio', '16:9'),
);

$result = $client->generations()->wait(
    $task['data']['id'],
    new WaitOptions(interval: 2.0, timeout: 600.0),
);

echo $result['data']['result']['videos'][0]['url'] . PHP_EOL;
