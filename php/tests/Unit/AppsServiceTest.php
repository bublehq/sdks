<?php

declare(strict_types=1);

namespace Buble\Tests\Unit;

use Buble\Apps\AppsService;
use PHPUnit\Framework\TestCase;

final class AppsServiceTest extends TestCase
{
    public function testCreatesAppGenerationWithFlatParameters(): void
    {
        $transport = new FakeTransport();
        $transport->enqueueResponse(['data' => ['id' => 'app_task_1', 'status' => 'pending']]);
        $service = new AppsService($transport);

        $service->generations()->create('video-background-remover', [
            'source_video' => ['https://example.com/source.mp4'],
            'subject_is_person' => true,
        ]);

        $body = $transport->requests[0]['body'];
        self::assertIsArray($body);
        self::assertArrayHasKey('source_video', $body);
        self::assertArrayHasKey('subject_is_person', $body);
        self::assertSame('/api/v1/apps/video-background-remover/generations', $transport->requests[0]['path']);
        self::assertSame(['https://example.com/source.mp4'], $body['source_video']);
        self::assertTrue($body['subject_is_person']);
    }
}
