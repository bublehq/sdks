<?php

declare(strict_types=1);

namespace Buble\Http;

final class FilePart
{
    public function __construct(
        public readonly string $path,
        public readonly string $filename,
        public readonly string $contentType,
        private readonly ?string $temporaryPath = null,
    ) {
    }

    public function toCurlFile(): \CURLFile
    {
        return new \CURLFile($this->path, $this->contentType, $this->filename);
    }

    public function cleanup(): void
    {
        if ($this->temporaryPath !== null && is_file($this->temporaryPath)) {
            @unlink($this->temporaryPath);
        }
    }
}
