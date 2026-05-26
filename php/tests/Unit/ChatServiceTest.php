<?php

declare(strict_types=1);

namespace Buble\Tests\Unit;

use Buble\Chat\ChatCompletionsService;
use Buble\Chat\GeminiService;
use Buble\Streaming\SseEvent;
use PHPUnit\Framework\TestCase;

final class ChatServiceTest extends TestCase
{
    public function testCreatesOpenAICompatibleChatWithoutWrappingResponse(): void
    {
        $transport = new FakeTransport();
        $transport->enqueueResponse([
            'id' => 'chatcmpl_1',
            'choices' => [['message' => ['content' => 'hello']]],
        ]);
        $service = new ChatCompletionsService($transport);

        $response = $service->create([
            'model' => 'openai/gpt-5.5',
            'messages' => [['role' => 'user', 'content' => 'hi']],
        ]);

        self::assertIsArray($response['choices']);
        self::assertIsArray($response['choices'][0]);
        self::assertIsArray($response['choices'][0]['message']);
        self::assertSame('hello', $response['choices'][0]['message']['content']);
        $body = $transport->requests[0]['body'];
        self::assertIsArray($body);
        self::assertArrayHasKey('stream', $body);
        self::assertSame('/api/v1/chat/completions', $transport->requests[0]['path']);
        self::assertFalse($body['stream']);
    }

    public function testStreamsOpenAIText(): void
    {
        $transport = new FakeTransport();
        $transport->enqueueEvent(new SseEvent(null, null, '{"choices":[{"delta":{"content":"hel"}}]}'));
        $transport->enqueueEvent(new SseEvent(null, null, '{"choices":[{"delta":{"content":"lo"}}]}'));
        $transport->enqueueEvent(new SseEvent(null, null, '[DONE]'));
        $service = new ChatCompletionsService($transport);

        $parts = iterator_to_array($service->streamText([
            'model' => 'openai/gpt-5.5',
            'messages' => [['role' => 'user', 'content' => 'hi']],
        ]));

        $body = $transport->requests[0]['body'];
        self::assertIsArray($body);
        self::assertArrayHasKey('stream', $body);
        self::assertSame(['hel', 'lo'], $parts);
        self::assertTrue($body['stream']);
    }

    public function testUsesGeminiGenerateContentPath(): void
    {
        $transport = new FakeTransport();
        $transport->enqueueResponse(['candidates' => []]);
        $service = new GeminiService($transport);

        $service->generateContent('openai/gpt-5.5', ['contents' => []]);

        self::assertSame('/api/v1beta/models/openai/gpt-5.5:generateContent', $transport->requests[0]['path']);
    }
}
