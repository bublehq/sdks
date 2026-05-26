<?php

declare(strict_types=1);

namespace Buble\Generations;

use Buble\Exception\BubleException;
use Buble\Exception\GenerationCanceledException;
use Buble\Exception\GenerationFailedException;
use Buble\Exception\TimeoutException;
use Buble\Http\TransportInterface;
use Buble\WaitOptions;

final class GenerationsService
{
    public function __construct(private readonly TransportInterface $transport)
    {
    }

    /**
     * @return array<string, mixed>
     */
    public function create(CreateGenerationRequest $request): array
    {
        return $this->transport->request('POST', '/api/v1/generations', $request->toRequestBody());
    }

    /**
     * @return array<string, mixed>
     */
    public function retrieve(string $generationId): array
    {
        return $this->transport->request('GET', '/api/v1/generations/' . rawurlencode($generationId));
    }

    /**
     * @return array<string, mixed>
     */
    public function wait(string $generationId, ?WaitOptions $options = null): array
    {
        $options ??= new WaitOptions();
        $deadline = microtime(true) + $options->timeout;

        while (true) {
            $envelope = $this->retrieve($generationId);
            $task = $envelope['data'] ?? null;
            if (!is_array($task)) {
                throw new BubleException('Buble API returned an empty generation response.');
            }
            $task = $this->stringKeyArray($task);

            $statusValue = $task['status'] ?? '';
            $status = is_string($statusValue) ? strtolower($statusValue) : '';
            if ($status === 'success') {
                return $envelope;
            }
            if ($status === 'failed') {
                throw new GenerationFailedException($task);
            }
            if ($status === 'canceled' || $status === 'cancelled') {
                throw new GenerationCanceledException($task);
            }
            if (microtime(true) >= $deadline) {
                throw new TimeoutException(
                    "Timed out waiting for Buble generation '{$generationId}'.",
                    $options->timeout,
                );
            }

            usleep(max(1, (int) round($options->interval * 1_000_000)));
        }
    }

    /**
     * @param array<mixed> $value
     * @return array<string, mixed>
     */
    private function stringKeyArray(array $value): array
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
