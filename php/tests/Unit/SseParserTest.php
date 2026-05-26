<?php

declare(strict_types=1);

namespace Buble\Tests\Unit;

use Buble\Streaming\SseParser;
use PHPUnit\Framework\TestCase;

final class SseParserTest extends TestCase
{
    public function testParsesMultilineDataEvent(): void
    {
        $parser = new SseParser();

        self::assertNull($parser->pushLine('event: message'));
        self::assertNull($parser->pushLine('data: hello'));
        self::assertNull($parser->pushLine('data: world'));
        $event = $parser->pushLine('');

        self::assertNotNull($event);
        self::assertSame('message', $event->event);
        self::assertSame("hello\nworld", $event->data);
    }
}
