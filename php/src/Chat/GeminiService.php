<?php

declare(strict_types=1);

namespace Buble\Chat;

use Buble\Http\TransportInterface;
use Buble\Streaming\SseEvent;
use Buble\Streaming\StreamText;

final class GeminiService
{
    public function __construct(private readonly TransportInterface $transport)
    {
    }

    /**
     * @param array<string, mixed> $body
     * @return array<string, mixed>
     */
    public function generateContent(string $model, array $body): array
    {
        return $this->transport->request(
            'POST',
            '/api/v1beta/models/' . $this->encodeModelPath($model) . ':generateContent',
            $body,
        );
    }

    /**
     * @param array<string, mixed> $body
     * @return \Generator<int, SseEvent>
     */
    public function streamGenerateContent(string $model, array $body): \Generator
    {
        yield from $this->transport->stream(
            '/api/v1beta/models/' . $this->encodeModelPath($model) . ':streamGenerateContent',
            $body,
        );
    }

    /**
     * @param array<string, mixed> $body
     * @return \Generator<int, string>
     */
    public function streamText(string $model, array $body): \Generator
    {
        yield from StreamText::fromEvents($this->streamGenerateContent($model, $body), 'gemini');
    }

    private function encodeModelPath(string $model): string
    {
        return implode('/', array_map('rawurlencode', explode('/', $model)));
    }
}
