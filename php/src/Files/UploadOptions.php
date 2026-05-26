<?php

declare(strict_types=1);

namespace Buble\Files;

final class UploadOptions
{
    public function __construct(
        public readonly ?string $fileType = null,
        public readonly ?string $model = null,
        public readonly ?string $mode = null,
    ) {
    }
}
