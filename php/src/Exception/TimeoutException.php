<?php

declare(strict_types=1);

namespace Buble\Exception;

final class TimeoutException extends BubleException
{
    public function __construct(string $message, public readonly float $timeout)
    {
        parent::__construct($message);
    }
}
