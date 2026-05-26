<?php

declare(strict_types=1);

namespace Buble\Chat;

use Buble\Http\TransportInterface;

final class ChatModelsService
{
    public function __construct(private readonly TransportInterface $transport)
    {
    }

    /**
     * @return array<string, mixed>
     */
    public function list(): array
    {
        return $this->transport->request('GET', '/api/v1/models');
    }
}
