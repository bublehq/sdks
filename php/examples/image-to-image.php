<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use Buble\BubleClient;
use Buble\Files\FileUpload;
use Buble\Files\UploadOptions;
use Buble\Generations\CreateGenerationRequest;

$client = BubleClient::fromEnv();

$uploaded = $client->files()->upload(
    FileUpload::fromPath('reference.png', 'image/png'),
    new UploadOptions(fileType: 'image', model: 'google/nano-banana', mode: 'image_to_image'),
);

$task = $client->generations()->create(new CreateGenerationRequest(
    model: 'google/nano-banana',
    mode: 'image_to_image',
    prompt: 'Turn this reference into a polished ecommerce hero image.',
    imageUrls: [$uploaded['data']['url']],
));

$result = $client->generations()->wait($task['data']['id']);
echo $result['data']['result']['images'][0]['url'] . PHP_EOL;
