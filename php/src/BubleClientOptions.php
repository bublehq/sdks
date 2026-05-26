<?php

declare(strict_types=1);

namespace Buble;

final class BubleClientOptions
{
    /**
     * @param array<string, string> $headers
     */
    public function __construct(
        public readonly ?string $apiKey = null,
        public readonly ?string $baseUrl = null,
        public readonly float $timeout = 60.0,
        public readonly array $headers = [],
    ) {
    }
}
