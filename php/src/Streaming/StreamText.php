<?php

declare(strict_types=1);

namespace Buble\Streaming;

final class StreamText
{
    /**
     * @param iterable<SseEvent> $events
     * @return \Generator<int, string>
     */
    public static function fromEvents(iterable $events, string $protocol): \Generator
    {
        foreach ($events as $event) {
            if ($event->data === '[DONE]') {
                return;
            }

            $decoded = json_decode($event->data, true);
            if (!is_array($decoded)) {
                continue;
            }

            foreach (self::extract(self::stringKeyArray($decoded), $protocol) as $text) {
                if ($text !== '') {
                    yield $text;
                }
            }
        }
    }

    /**
     * @param array<string, mixed> $payload
     * @return list<string>
     */
    private static function extract(array $payload, string $protocol): array
    {
        return match ($protocol) {
            'openai' => self::extractOpenAI($payload),
            'anthropic' => self::extractAnthropic($payload),
            'gemini' => self::extractGemini($payload),
            default => [],
        };
    }

    /**
     * @param array<string, mixed> $payload
     * @return list<string>
     */
    private static function extractOpenAI(array $payload): array
    {
        $out = [];
        $choices = $payload['choices'] ?? [];
        if (!is_array($choices)) {
            return $out;
        }

        foreach ($choices as $choice) {
            if (!is_array($choice)) {
                continue;
            }
            $text = null;
            if (isset($choice['delta']) && is_array($choice['delta']) && isset($choice['delta']['content'])) {
                $text = $choice['delta']['content'];
            } elseif (
                isset($choice['message'])
                && is_array($choice['message'])
                && isset($choice['message']['content'])
            ) {
                $text = $choice['message']['content'];
            } elseif (isset($choice['text'])) {
                $text = $choice['text'];
            }
            if (is_string($text)) {
                $out[] = $text;
            }
        }

        return $out;
    }

    /**
     * @param array<string, mixed> $payload
     * @return list<string>
     */
    private static function extractAnthropic(array $payload): array
    {
        $out = [];
        $delta = isset($payload['delta']) && is_array($payload['delta']) ? ($payload['delta']['text'] ?? null) : null;
        if (is_string($delta)) {
            $out[] = $delta;
        }
        $contentBlock = isset($payload['content_block']) && is_array($payload['content_block'])
            ? ($payload['content_block']['text'] ?? null)
            : null;
        if (is_string($contentBlock)) {
            $out[] = $contentBlock;
        }

        return $out;
    }

    /**
     * @param array<string, mixed> $payload
     * @return list<string>
     */
    private static function extractGemini(array $payload): array
    {
        $out = [];
        $candidates = $payload['candidates'] ?? [];
        if (!is_array($candidates)) {
            return $out;
        }
        foreach ($candidates as $candidate) {
            if (!is_array($candidate)) {
                continue;
            }
            $parts = isset($candidate['content']) && is_array($candidate['content'])
                ? ($candidate['content']['parts'] ?? [])
                : [];
            if (!is_array($parts)) {
                continue;
            }
            foreach ($parts as $part) {
                $text = is_array($part) ? ($part['text'] ?? null) : null;
                if (is_string($text)) {
                    $out[] = $text;
                }
            }
        }

        return $out;
    }

    /**
     * @param array<mixed> $value
     * @return array<string, mixed>
     */
    private static function stringKeyArray(array $value): array
    {
        $out = [];
        foreach ($value as $key => $item) {
            if (is_string($key)) {
                $out[$key] = $item;
            }
        }

        return $out;
    }
}
