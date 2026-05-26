<?php

declare(strict_types=1);

namespace Buble;

final class RequestOptions
{
    /**
     * @param array<string, string> $headers
     * @param array<string, string> $query
     */
    public function __construct(
        public readonly array $headers = [],
        public readonly array $query = [],
    ) {
    }
}
