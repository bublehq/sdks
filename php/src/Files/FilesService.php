<?php

declare(strict_types=1);

namespace Buble\Files;

use Buble\Http\TransportInterface;

final class FilesService
{
    public function __construct(private readonly TransportInterface $transport)
    {
    }

    /**
     * @return array<string, mixed>
     */
    public function upload(FileUpload $file, ?UploadOptions $options = null): array
    {
        $options ??= new UploadOptions();
        $filePart = $file->toFilePart();

        try {
            return $this->transport->multipart('/api/v1/files', [
                'file_type' => $options->fileType,
                'model' => $options->model,
                'mode' => $options->mode,
            ], $filePart);
        } finally {
            $filePart->cleanup();
        }
    }
}
