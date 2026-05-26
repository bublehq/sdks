<?php

declare(strict_types=1);

namespace Buble\Generations;

use Buble\Exception\UnsupportedGenerationFieldException;

final class CreateGenerationRequest
{
    /** @var array<string, true> */
    private const FORBIDDEN_FIELDS = [
        'input' => true,
        'options' => true,
        'scene' => true,
        'sub_mode_id' => true,
        'subModeId' => true,
        'provider' => true,
        'mediaType' => true,
        'media_type' => true,
        'images' => true,
        'image_input' => true,
        'video_input' => true,
        'audio_input' => true,
    ];

    /**
     * @param list<string>|null $imageUrls
     * @param list<string>|null $videoUrls
     * @param list<string>|null $audioUrls
     * @param array<string, mixed> $params
     */
    public function __construct(
        public readonly ?string $model = null,
        public readonly ?string $mode = null,
        public readonly ?string $prompt = null,
        public readonly ?array $imageUrls = null,
        public readonly ?string $startFrame = null,
        public readonly ?string $endFrame = null,
        public readonly ?array $videoUrls = null,
        public readonly ?array $audioUrls = null,
        public readonly ?bool $isPublic = null,
        public readonly ?bool $copyProtected = null,
        private array $params = [],
    ) {
        foreach (array_keys($this->params) as $key) {
            $this->assertSupportedField((string) $key);
        }
    }

    public static function make(?string $model = null, ?string $mode = null, ?string $prompt = null): self
    {
        return new self(model: $model, mode: $mode, prompt: $prompt);
    }

    public function withParam(string $key, mixed $value): self
    {
        $this->assertSupportedField($key);
        $clone = clone $this;
        $clone->params[$key] = $value;

        return $clone;
    }

    /**
     * @param array<string, mixed> $params
     */
    public function withParams(array $params): self
    {
        $clone = clone $this;
        foreach ($params as $key => $value) {
            $clone = $clone->withParam((string) $key, $value);
        }

        return $clone;
    }

    /**
     * @return array<string, mixed>
     */
    public function toRequestBody(): array
    {
        $body = [];
        $this->put($body, 'model', $this->model);
        $this->put($body, 'mode', $this->mode);
        $this->put($body, 'prompt', $this->prompt);
        $this->put($body, 'image_urls', $this->imageUrls);
        $this->put($body, 'start_frame', $this->startFrame);
        $this->put($body, 'end_frame', $this->endFrame);
        $this->put($body, 'video_urls', $this->videoUrls);
        $this->put($body, 'audio_urls', $this->audioUrls);
        $this->put($body, 'is_public', $this->isPublic);
        $this->put($body, 'copy_protected', $this->copyProtected);

        foreach ($this->params as $key => $value) {
            if ($value === null) {
                continue;
            }
            $this->assertSupportedField((string) $key);
            $body[(string) $key] = $value;
        }

        return $body;
    }

    /**
     * @param array<string, mixed> $body
     */
    private function put(array &$body, string $key, mixed $value): void
    {
        if ($value === null || $value === '' || $value === []) {
            return;
        }
        $this->assertSupportedField($key);
        $body[$key] = $value;
    }

    private function assertSupportedField(string $key): void
    {
        if (isset(self::FORBIDDEN_FIELDS[$key])) {
            throw new UnsupportedGenerationFieldException($key);
        }
    }
}
