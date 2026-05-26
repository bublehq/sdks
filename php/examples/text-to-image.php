<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use Buble\BubleClient;
use Buble\Generations\CreateGenerationRequest;

$client = BubleClient::fromEnv();

$task = $client->generations()->create(
    CreateGenerationRequest::make(
        model: 'google/nano-banana',
        mode: 'text_to_image',
        prompt: 'A cinematic product photo of a matte black espresso cup',
    )->withParam('aspect_ratio', '1:1')
     ->withParam('output_format', 'png'),
);

$result = $client->generations()->wait($task['data']['id']);
echo $result['data']['result']['images'][0]['url'] . PHP_EOL;
