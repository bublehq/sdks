<?php

declare(strict_types=1);

namespace Buble\Files;

use Buble\Exception\BubleException;
use Buble\Http\FilePart;

final class FileUpload
{
    private function __construct(
        private readonly ?string $path,
        private readonly ?string $contents,
        public readonly string $filename,
        public readonly string $contentType,
    ) {
    }

    public static function fromPath(string $path, ?string $contentType = null): self
    {
        if ($path === '' || !is_file($path)) {
            throw new BubleException('Upload file path does not exist: ' . $path);
        }

        return new self($path, null, basename($path), $contentType ?? 'application/octet-stream');
    }

    public static function fromBytes(string $contents, string $filename, ?string $contentType = null): self
    {
        if ($filename === '') {
            throw new BubleException('Upload filename is required.');
        }

        return new self(null, $contents, $filename, $contentType ?? 'application/octet-stream');
    }

    /**
     * @param resource $stream
     */
    public static function fromStream($stream, string $filename, ?string $contentType = null): self
    {
        if (!is_resource($stream)) {
            throw new BubleException('Upload stream must be a PHP resource.');
        }
        $contents = stream_get_contents($stream);
        if ($contents === false) {
            throw new BubleException('Failed to read upload stream.');
        }

        return self::fromBytes($contents, $filename, $contentType);
    }

    public function toFilePart(): FilePart
    {
        if ($this->path !== null) {
            return new FilePart($this->path, $this->filename, $this->contentType);
        }

        $temporaryPath = tempnam(sys_get_temp_dir(), 'buble-upload-');
        if ($temporaryPath === false) {
            throw new BubleException('Failed to create a temporary upload file.');
        }
        if (file_put_contents($temporaryPath, $this->contents ?? '') === false) {
            @unlink($temporaryPath);
            throw new BubleException('Failed to write temporary upload file.');
        }

        return new FilePart($temporaryPath, $this->filename, $this->contentType, $temporaryPath);
    }
}
