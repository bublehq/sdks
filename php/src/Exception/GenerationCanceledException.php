<?php

declare(strict_types=1);

namespace Buble\Exception;

final class GenerationCanceledException extends BubleException
{
    /**
     * @param array<string, mixed> $task
     */
    public function __construct(public readonly array $task)
    {
        $id = $task['id'] ?? '';
        parent::__construct(sprintf("Buble generation '%s' was canceled.", is_string($id) ? $id : ''));
    }
}
