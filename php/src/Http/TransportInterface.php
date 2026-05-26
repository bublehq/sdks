<?php

declare(strict_types=1);

namespace Buble\Http;

use Buble\RequestOptions;
use Buble\Streaming\SseEvent;

interface TransportInterface
{
    /**
     * @param array<string, mixed>|null $body
     * @return array<string, mixed>
     */
    public function request(string $method, string $path, ?array $body = null, ?RequestOptions $options = null): array;

    /**
     * @param array<string, mixed> $fields
     * @return array<string, mixed>
     */
    public function multipart(string $path, array $fields, FilePart $file, ?RequestOptions $options = null): array;

    /**
     * @param array<string, mixed> $body
     * @return \Generator<int, SseEvent>
     */
    public function stream(string $path, array $body, ?RequestOptions $options = null): \Generator;
}
