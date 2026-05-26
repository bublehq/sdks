<?php

declare(strict_types=1);

namespace Buble\Tests\Unit;

use Buble\Exception\UnsupportedGenerationFieldException;
use Buble\Generations\CreateGenerationRequest;
use Buble\Generations\GenerationsService;
use Buble\WaitOptions;
use PHPUnit\Framework\TestCase;

final class GenerationsServiceTest extends TestCase
{
    public function testCreatesFlatGenerationBody(): void
    {
        $transport = new FakeTransport();
        $transport->enqueueResponse(['data' => ['id' => 'task_1', 'status' => 'pending']]);
        $service = new GenerationsService($transport);

        $service->create(CreateGenerationRequest::make(
            model: 'google/nano-banana',
            mode: 'text_to_image',
            prompt: 'hello',
        )->withParam('aspect_ratio', '1:1')->withParam('output_format', 'png'));

        $body = $transport->requests[0]['body'];
        self::assertIsArray($body);
        self::assertArrayHasKey('model', $body);
        self::assertArrayHasKey('aspect_ratio', $body);
        self::assertSame('google/nano-banana', $body['model']);
        self::assertSame('1:1', $body['aspect_ratio']);
        self::assertArrayNotHasKey('params', $body);
    }

    public function testRejectsInternalGenerationFields(): void
    {
        $this->expectException(UnsupportedGenerationFieldException::class);
        CreateGenerationRequest::make(model: 'google/nano-banana')->withParam('input', ['prompt' => 'x']);
    }

    public function testWaitsForSuccess(): void
    {
        $transport = new FakeTransport();
        $transport->enqueueResponse(['data' => ['id' => 'task_1', 'status' => 'processing']]);
        $transport->enqueueResponse([
            'data' => [
                'id' => 'task_1',
                'status' => 'success',
                'result' => ['images' => [['url' => 'https://example.com/out.png']]],
            ],
        ]);
        $service = new GenerationsService($transport);

        $result = $service->wait('task_1', new WaitOptions(interval: 0.001, timeout: 1.0));

        self::assertIsArray($result['data']);
        self::assertIsArray($result['data']['result']);
        self::assertIsArray($result['data']['result']['images']);
        self::assertIsArray($result['data']['result']['images'][0]);
        self::assertSame('https://example.com/out.png', $result['data']['result']['images'][0]['url']);
        self::assertSame('/api/v1/generations/task_1', $transport->requests[0]['path']);
    }
}
