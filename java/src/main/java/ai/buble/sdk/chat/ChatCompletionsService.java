package ai.buble.sdk.chat;

import ai.buble.sdk.RequestOptions;
import ai.buble.sdk.http.BubleHttpClient;
import ai.buble.sdk.streaming.BubleStream;
import ai.buble.sdk.streaming.StreamProtocol;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;

import java.net.http.HttpResponse;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * OpenAI-compatible chat completion methods.
 */
public final class ChatCompletionsService {
    private static final TypeReference<Map<String, JsonNode>> CHAT_RESPONSE =
            new TypeReference<Map<String, JsonNode>>() {};

    private final BubleHttpClient http;

    public ChatCompletionsService(BubleHttpClient http) {
        this.http = http;
    }

    public Map<String, JsonNode> create(Map<String, Object> body) {
        Map<String, Object> payload = copy(body);
        payload.put("stream", false);
        return http.post("/api/v1/chat/completions", payload, CHAT_RESPONSE);
    }

    public BubleStream stream(Map<String, Object> body) {
        Map<String, Object> payload = copy(body);
        payload.put("stream", true);
        HttpResponse<java.io.InputStream> response = http.stream("/api/v1/chat/completions", payload, RequestOptions.none());
        return new BubleStream(response.body(), http.getObjectMapper(), StreamProtocol.OPENAI);
    }

    static Map<String, Object> copy(Map<String, Object> input) {
        return input == null ? new LinkedHashMap<String, Object>() : new LinkedHashMap<String, Object>(input);
    }
}
