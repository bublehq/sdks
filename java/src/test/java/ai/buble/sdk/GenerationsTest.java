package ai.buble.sdk;

import ai.buble.sdk.generations.CreateGenerationRequest;
import ai.buble.sdk.generations.GenerationTask;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

final class GenerationsTest {
    @Test
    void createsFlatGenerationBody() throws Exception {
        try (TestHttpServer server = new TestHttpServer(request ->
                new TestHttpServer.Response(200, "{\"data\":{\"id\":\"task_1\",\"status\":\"pending\"}}"))) {
            BubleClient client = BubleClient.builder().apiKey("sk_test").baseUrl(server.url()).build();

            client.generations().create(CreateGenerationRequest.builder()
                    .model("google/nano-banana")
                    .mode("text_to_image")
                    .prompt("hello")
                    .param("aspect_ratio", "1:1")
                    .param("output_format", "png")
                    .build());

            String body = server.requests().get(0).body;
            assertTrue(body.contains("\"model\":\"google/nano-banana\""));
            assertTrue(body.contains("\"aspect_ratio\":\"1:1\""));
            assertFalse(body.contains("\"params\""));
        }
    }

    @Test
    void rejectsInternalGenerationFields() {
        assertThrows(UnsupportedGenerationFieldException.class, () ->
                CreateGenerationRequest.builder()
                        .model("google/nano-banana")
                        .param("input", Map.of("prompt", "x"))
                        .build());
    }

    @Test
    void waitsForSuccess() throws Exception {
        final int[] calls = {0};
        try (TestHttpServer server = new TestHttpServer(request -> {
            calls[0]++;
            if (calls[0] == 1) {
                return new TestHttpServer.Response(200, "{\"data\":{\"id\":\"task_1\",\"status\":\"processing\"}}");
            }
            return new TestHttpServer.Response(200, "{\"data\":{\"id\":\"task_1\",\"status\":\"success\",\"result\":{\"images\":[{\"url\":\"https://example.com/out.png\"}]}}}");
        })) {
            BubleClient client = BubleClient.builder().apiKey("sk_test").baseUrl(server.url()).build();

            Envelope<GenerationTask> result = client.generations().wait(
                    "task_1",
                    WaitOptions.builder().interval(Duration.ofMillis(1)).timeout(Duration.ofSeconds(1)).build());

            assertEquals("https://example.com/out.png", result.getData().getResult().getImages().get(0).getUrl());
            assertEquals("/api/v1/generations/task_1", server.requests().get(0).path);
        }
    }
}
