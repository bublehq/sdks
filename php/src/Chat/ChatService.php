<?php

declare(strict_types=1);

namespace Buble\Chat;

use Buble\Http\TransportInterface;

final class ChatService
{
    private ChatModelsService $models;
    private ChatCompletionsService $completions;
    private MessagesService $messages;
    private GeminiService $gemini;

    public function __construct(TransportInterface $transport)
    {
        $this->models = new ChatModelsService($transport);
        $this->completions = new ChatCompletionsService($transport);
        $this->messages = new MessagesService($transport);
        $this->gemini = new GeminiService($transport);
    }

    public function models(): ChatModelsService
    {
        return $this->models;
    }

    public function completions(): ChatCompletionsService
    {
        return $this->completions;
    }

    public function messages(): MessagesService
    {
        return $this->messages;
    }

    public function gemini(): GeminiService
    {
        return $this->gemini;
    }
}
