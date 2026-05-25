package ai.buble.sdk.chat;

import ai.buble.sdk.http.BubleHttpClient;

/**
 * Chat model discovery and protocol-compatible chat methods.
 */
public final class ChatService {
    private final ChatModelsService models;
    private final ChatCompletionsService completions;
    private final MessagesService messages;
    private final GeminiService gemini;

    public ChatService(BubleHttpClient http) {
        this.models = new ChatModelsService(http);
        this.completions = new ChatCompletionsService(http);
        this.messages = new MessagesService(http);
        this.gemini = new GeminiService(http);
    }

    public ChatModelsService models() {
        return models;
    }

    public ChatCompletionsService completions() {
        return completions;
    }

    public MessagesService messages() {
        return messages;
    }

    public GeminiService gemini() {
        return gemini;
    }
}
