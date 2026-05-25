package ai.buble.sdk.chat;

import ai.buble.sdk.http.BubleHttpClient;
import com.fasterxml.jackson.core.type.TypeReference;

/**
 * Chat model discovery methods.
 */
public final class ChatModelsService {
    private static final TypeReference<ChatModelList> CHAT_MODEL_LIST =
            new TypeReference<ChatModelList>() {};

    private final BubleHttpClient http;

    public ChatModelsService(BubleHttpClient http) {
        this.http = http;
    }

    public ChatModelList list() {
        return http.get("/api/v1/models", CHAT_MODEL_LIST);
    }
}
