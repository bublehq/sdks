<?php

declare(strict_types=1);

namespace Buble\Tests\Unit;

use Buble\Http\FilePart;
use Buble\Http\TransportInterface;
use Buble\RequestOptions;
use Buble\Streaming\SseEvent;

final class FakeTransport implements TransportInterface
{
    /** @var list<array{method:string,path:string,body:array<string,mixed>|null,options:RequestOptions|null}> */
    public array $requests = [];

    /** @var list<array{path:string,fields:array<string,mixed>,file:FilePart,options:RequestOptions|null}> */
    public array $uploads = [];

    /** @var list<array<string, mixed>> */
    private array $responses = [];

    /** @var list<SseEvent> */
    private array $events = [];

    /**
     * @param array<string, mixed> $response
     */
    public function enqueueResponse(array $response): void
    {
        $this->responses[] = $response;
    }

    public function enqueueEvent(SseEvent $event): void
    {
        $this->events[] = $event;
    }

    public function request(string $method, string $path, ?array $body = null, ?RequestOptions $options = null): array
    {
        $this->requests[] = compact('method', 'path', 'body', 'options');
        return array_shift($this->responses) ?? [];
    }

    public function multipart(string $path, array $fields, FilePart $file, ?RequestOptions $options = null): array
    {
        $this->uploads[] = compact('path', 'fields', 'file', 'options');
        return array_shift($this->responses) ?? [];
    }

    public function stream(string $path, array $body, ?RequestOptions $options = null): \Generator
    {
        $this->requests[] = [
            'method' => 'STREAM',
            'path' => $path,
            'body' => $body,
            'options' => $options,
        ];

        foreach ($this->events as $event) {
            yield $event;
        }
    }
}
