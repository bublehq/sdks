<?php

declare(strict_types=1);

namespace Buble\Apps;

use Buble\Http\TransportInterface;

final class AppsService
{
    private AppGenerationsService $generations;

    public function __construct(private readonly TransportInterface $transport)
    {
        $this->generations = new AppGenerationsService($transport);
    }

    /**
     * @return array<string, mixed>
     */
    public function list(): array
    {
        return $this->transport->request('GET', '/api/v1/apps');
    }

    /**
     * @return array<string, mixed>
     */
    public function retrieve(string $appId): array
    {
        return $this->transport->request('GET', '/api/v1/apps/' . rawurlencode($appId));
    }

    public function generations(): AppGenerationsService
    {
        return $this->generations;
    }
}
