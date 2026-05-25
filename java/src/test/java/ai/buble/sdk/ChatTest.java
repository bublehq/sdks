package ai.buble.sdk;

import ai.buble.sdk.streaming.BubleStream;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

final class ChatTest {
    @Test
    void streamsOpenAIText() throws Exception {
        String sse = "data: {\"choices\":[{\"delta\":{\"content\":\"Hel\"}}]}\n\n"
                + "data: {\"choices\":[{\"delta\":{\"content\":\"lo\"}}]}\n\n"
                + "data: [DONE]\n\n";
        try (TestHttpServer server = new TestHttpServer(request ->
                new TestHttpServer.Response(200, sse).header("Content-Type", "text/event-stream"))) {
            BubleClient client = BubleClient.builder().apiKey("sk_test").baseUrl(server.url()).build();

            StringBuilder out = new StringBuilder();
            try (BubleStream stream = client.chat().completions().stream(Map.of(
                    "model", "openai/gpt-5.5",
                    "messages", List.of(Map.of("role", "user", "content", "hello"))
            ))) {
                while (stream.next()) {
                    out.append(stream.text());
                }
            }

            assertEquals("Hello", out.toString());
            assertEquals("/api/v1/chat/completions", server.requests().get(0).path);
            assertTrue(server.requests().get(0).body.contains("\"stream\":true"));
        }
    }

    @Test
    void encodesGeminiModelPath() throws Exception {
        try (TestHttpServer server = new TestHttpServer(request ->
                new TestHttpServer.Response(200, "{\"candidates\":[]}"))) {
            BubleClient client = BubleClient.builder().apiKey("sk_test").baseUrl(server.url()).build();

            client.chat().gemini().generateContent("google/gemini 2.5", Map.of("contents", List.of()));

            assertEquals("/api/v1beta/models/google/gemini%202.5:generateContent", server.requests().get(0).path);
        }
    }
}
