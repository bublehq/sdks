package ai.buble.sdk;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

final class AppsTest {
    @Test
    void createsAppGenerationWithEncodedPath() throws Exception {
        try (TestHttpServer server = new TestHttpServer(request ->
                new TestHttpServer.Response(200, "{\"data\":{\"id\":\"app_task_1\",\"status\":\"pending\"}}"))) {
            BubleClient client = BubleClient.builder().apiKey("sk_test").baseUrl(server.url()).build();

            client.apps().generations().create("video/background remover", Map.of(
                    "source_video", List.of("https://example.com/source.mp4"),
                    "refine_foreground_edges", true
            ));

            assertEquals("/api/v1/apps/video%2Fbackground%20remover/generations", server.requests().get(0).path);
            assertTrue(server.requests().get(0).body.contains("\"source_video\""));
        }
    }
}
