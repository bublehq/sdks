package ai.buble.sdk.chat;

import ai.buble.sdk.RequestOptions;
import ai.buble.sdk.http.BubleHttpClient;
import ai.buble.sdk.streaming.BubleStream;
import ai.buble.sdk.streaming.StreamProtocol;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;

import java.net.http.HttpResponse;
import java.util.Map;

/**
 * Anthropic Messages-compatible methods.
 */
public final class MessagesService {
    private static final TypeReference<Map<String, JsonNode>> CHAT_RESPONSE =
            new TypeReference<Map<String, JsonNode>>() {};

    private final BubleHttpClient http;

    public MessagesService(BubleHttpClient http) {
        this.http = http;
    }

    public Map<String, JsonNode> create(Map<String, Object> body) {
        Map<String, Object> payload = ChatCompletionsService.copy(body);
        payload.put("stream", false);
        return http.post("/api/v1/messages", payload, CHAT_RESPONSE);
    }

    public BubleStream stream(Map<String, Object> body) {
        Map<String, Object> payload = ChatCompletionsService.copy(body);
        payload.put("stream", true);
        HttpResponse<java.io.InputStream> response = http.stream("/api/v1/messages", payload, RequestOptions.none());
        return new BubleStream(response.body(), http.getObjectMapper(), StreamProtocol.ANTHROPIC);
    }
}
