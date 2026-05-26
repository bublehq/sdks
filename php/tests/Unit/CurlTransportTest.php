<?php

declare(strict_types=1);

namespace Buble\Tests\Unit;

use Buble\Http\CurlTransport;
use PHPUnit\Framework\TestCase;
use ReflectionClass;

final class CurlTransportTest extends TestCase
{
    public function testParsesHttpStatusFromStreamWrapperHeaders(): void
    {
        $transport = new CurlTransport('sk_test', 'https://buble.ai', 60.0);
        $method = (new ReflectionClass($transport))->getMethod('statusFromResponseHeaders');

        $status = $method->invoke($transport, [
            'HTTP/2 401',
            'content-type: application/json',
        ]);

        self::assertSame(401, $status);
    }

    public function testTransportDoesNotCallDeprecatedCurlClose(): void
    {
        $source = file_get_contents(__DIR__ . '/../../src/Http/CurlTransport.php');

        self::assertIsString($source);
        self::assertStringNotContainsString('curl_close(', $source);
    }
}
