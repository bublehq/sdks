<?php

declare(strict_types=1);

namespace Buble\Chat;

use Buble\Http\TransportInterface;
use Buble\Streaming\SseEvent;
use Buble\Streaming\StreamText;

final class MessagesService
{
    public function __construct(private readonly TransportInterface $transport)
    {
    }

    /**
     * @param array<string, mixed> $body
     * @return array<string, mixed>
     */
    public function create(array $body): array
    {
        $body['stream'] = false;
        return $this->transport->request('POST', '/api/v1/messages', $body);
    }

    /**
     * @param array<string, mixed> $body
     * @return \Generator<int, SseEvent>
     */
    public function stream(array $body): \Generator
    {
        $body['stream'] = true;
        yield from $this->transport->stream('/api/v1/messages', $body);
    }

    /**
     * @param array<string, mixed> $body
     * @return \Generator<int, string>
     */
    public function streamText(array $body): \Generator
    {
        yield from StreamText::fromEvents($this->stream($body), 'anthropic');
    }
}
