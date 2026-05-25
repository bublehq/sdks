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
 * Gemini-compatible content generation methods.
 */
public final class GeminiService {
    private static final TypeReference<Map<String, JsonNode>> CHAT_RESPONSE =
            new TypeReference<Map<String, JsonNode>>() {};

    private final BubleHttpClient http;

    public GeminiService(BubleHttpClient http) {
        this.http = http;
    }

    public Map<String, JsonNode> generateContent(String model, Map<String, Object> body) {
        String path = "/api/v1beta/models/" + BubleHttpClient.encodeModelPath(model) + ":generateContent";
        return http.post(path, ChatCompletionsService.copy(body), CHAT_RESPONSE);
    }

    public BubleStream streamGenerateContent(String model, Map<String, Object> body) {
        String path = "/api/v1beta/models/" + BubleHttpClient.encodeModelPath(model) + ":streamGenerateContent";
        HttpResponse<java.io.InputStream> response = http.stream(path, ChatCompletionsService.copy(body), RequestOptions.none());
        return new BubleStream(response.body(), http.getObjectMapper(), StreamProtocol.GEMINI);
    }
}
