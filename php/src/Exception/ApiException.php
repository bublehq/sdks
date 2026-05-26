<?php

declare(strict_types=1);

namespace Buble\Exception;

final class ApiException extends BubleException
{
    /**
     * @param array<string, mixed>|null $details
     */
    public function __construct(
        public readonly int $statusCode,
        public readonly ?string $apiCode,
        string $message,
        public readonly ?array $details = null,
        public readonly ?string $responseBody = null,
    ) {
        parent::__construct($message, $statusCode);
    }
}
