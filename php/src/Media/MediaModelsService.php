<?php

declare(strict_types=1);

namespace Buble\Media;

use Buble\Http\TransportInterface;
use Buble\RequestOptions;

final class MediaModelsService
{
    public function __construct(private readonly TransportInterface $transport)
    {
    }

    /**
     * @return array<string, mixed>
     */
    public function list(?string $mediaType = null): array
    {
        $query = [];
        if ($mediaType !== null && $mediaType !== '') {
            $query['media_type'] = $mediaType;
        }

        return $this->transport->request('GET', '/api/v1/media_models', options: new RequestOptions(query: $query));
    }
}
