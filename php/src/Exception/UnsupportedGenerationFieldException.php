<?php

declare(strict_types=1);

namespace Buble\Exception;

final class UnsupportedGenerationFieldException extends BubleException
{
    public function __construct(public readonly string $field)
    {
        parent::__construct(sprintf(
            "'%s' is an internal Buble workflow field and cannot be sent to the public generation API.",
            $field,
        ));
    }
}
