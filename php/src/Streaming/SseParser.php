<?php

declare(strict_types=1);

namespace Buble\Streaming;

final class SseParser
{
    private ?string $id = null;
    private ?string $event = null;

    /** @var list<string> */
    private array $data = [];

    public function pushLine(string $line): ?SseEvent
    {
        if ($line === '') {
            return $this->flush();
        }
        if (str_starts_with($line, ':')) {
            return null;
        }

        $separator = strpos($line, ':');
        $field = $separator === false ? $line : substr($line, 0, $separator);
        $value = $separator === false ? '' : ltrim(substr($line, $separator + 1), ' ');

        if ($field === 'id') {
            $this->id = $value;
        } elseif ($field === 'event') {
            $this->event = $value;
        } elseif ($field === 'data') {
            $this->data[] = $value;
        }

        return null;
    }

    public function finish(): ?SseEvent
    {
        return $this->flush();
    }

    private function flush(): ?SseEvent
    {
        if ($this->data === []) {
            $this->id = null;
            $this->event = null;
            return null;
        }

        $event = new SseEvent($this->id, $this->event, implode("\n", $this->data));
        $this->id = null;
        $this->event = null;
        $this->data = [];

        return $event;
    }
}
