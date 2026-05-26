<?php

declare(strict_types=1);

namespace Buble;

use Buble\Apps\AppsService;
use Buble\Chat\ChatService;
use Buble\Exception\BubleException;
use Buble\Files\FilesService;
use Buble\Generations\GenerationsService;
use Buble\Http\CurlTransport;
use Buble\Http\TransportInterface;
use Buble\Media\MediaModelsService;

final class BubleClient
{
    public const DEFAULT_BASE_URL = 'https://buble.ai';

    private TransportInterface $transport;
    private MediaModelsService $mediaModels;
    private FilesService $files;
    private GenerationsService $generations;
    private AppsService $apps;
    private ChatService $chat;

    /**
     * @param BubleClientOptions|array{
     *   apiKey?: string,
     *   baseUrl?: string,
     *   timeout?: int|float,
     *   headers?: array<string, string>
     * }|null $options
     */
    public function __construct(BubleClientOptions|array|null $options = null, ?TransportInterface $transport = null)
    {
        if (is_array($options)) {
            $options = new BubleClientOptions(
                apiKey: $options['apiKey'] ?? null,
                baseUrl: $options['baseUrl'] ?? null,
                timeout: isset($options['timeout']) ? (float) $options['timeout'] : 60.0,
                headers: $options['headers'] ?? [],
            );
        }
        $options ??= new BubleClientOptions();

        $apiKey = $this->firstNonEmpty($options->apiKey, getenv('BUBLE_API_KEY') ?: null);
        if ($apiKey === null) {
            throw new BubleException('Missing Buble API key. Pass apiKey or set BUBLE_API_KEY.');
        }

        $baseUrl = $this->firstNonEmpty($options->baseUrl, getenv('BUBLE_BASE_URL') ?: null, self::DEFAULT_BASE_URL)
            ?? self::DEFAULT_BASE_URL;
        $this->transport = $transport ?? new CurlTransport($apiKey, $baseUrl, $options->timeout, $options->headers);

        $this->mediaModels = new MediaModelsService($this->transport);
        $this->files = new FilesService($this->transport);
        $this->generations = new GenerationsService($this->transport);
        $this->apps = new AppsService($this->transport);
        $this->chat = new ChatService($this->transport);
    }

    public static function fromEnv(): self
    {
        return new self();
    }

    public function mediaModels(): MediaModelsService
    {
        return $this->mediaModels;
    }

    public function files(): FilesService
    {
        return $this->files;
    }

    public function generations(): GenerationsService
    {
        return $this->generations;
    }

    public function apps(): AppsService
    {
        return $this->apps;
    }

    public function chat(): ChatService
    {
        return $this->chat;
    }

    private function firstNonEmpty(?string ...$values): ?string
    {
        foreach ($values as $value) {
            if ($value !== null && trim($value) !== '') {
                return $value;
            }
        }

        return null;
    }
}
