<?php

declare(strict_types=1);

namespace Buble\Tests\Unit;

use Buble\Files\FileUpload;
use Buble\Files\FilesService;
use Buble\Files\UploadOptions;
use PHPUnit\Framework\TestCase;

final class FilesServiceTest extends TestCase
{
    public function testUploadsMultipartFileAndFields(): void
    {
        $transport = new FakeTransport();
        $transport->enqueueResponse(['data' => ['id' => 'file_1', 'url' => 'https://example.com/file.png']]);
        $service = new FilesService($transport);

        $service->upload(
            FileUpload::fromBytes('abc', 'reference.png', 'image/png'),
            new UploadOptions(fileType: 'image', model: 'google/nano-banana', mode: 'image_to_image'),
        );

        self::assertSame('/api/v1/files', $transport->uploads[0]['path']);
        self::assertSame('image', $transport->uploads[0]['fields']['file_type']);
        self::assertSame('google/nano-banana', $transport->uploads[0]['fields']['model']);
        self::assertSame('image_to_image', $transport->uploads[0]['fields']['mode']);
        self::assertSame('reference.png', $transport->uploads[0]['file']->filename);
    }
}
