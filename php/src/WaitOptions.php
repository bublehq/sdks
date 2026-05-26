<?php

declare(strict_types=1);

namespace Buble;

final class WaitOptions
{
    public function __construct(
        public readonly float $interval = 2.0,
        public readonly float $timeout = 600.0,
    ) {
    }
}
