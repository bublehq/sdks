package ai.buble.sdk;

import ai.buble.sdk.files.FileUpload;
import ai.buble.sdk.files.UploadOptions;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

final class FilesTest {
    @Test
    void uploadsMultipartFile() throws Exception {
        try (TestHttpServer server = new TestHttpServer(request ->
                new TestHttpServer.Response(200, "{\"data\":{\"object\":\"file\",\"url\":\"https://example.com/reference.png\",\"key\":\"k\",\"file_type\":\"image\",\"content_type\":\"image/png\",\"size\":3,\"filename\":\"reference.png\"}}"))) {
            BubleClient client = BubleClient.builder().apiKey("sk_test").baseUrl(server.url()).build();

            client.files().upload(
                    FileUpload.fromBytes("abc".getBytes(StandardCharsets.UTF_8), "reference.png"),
                    UploadOptions.builder()
                            .fileType("image")
                            .model("google/nano-banana")
                            .mode("image_to_image")
                            .build());

            TestHttpServer.CapturedRequest request = server.requests().get(0);
            assertEquals("/api/v1/files", request.path);
            assertTrue(request.contentType.startsWith("multipart/form-data; boundary="));
            assertTrue(request.body.contains("name=\"file_type\""));
            assertTrue(request.body.contains("google/nano-banana"));
            assertTrue(request.body.contains("filename=\"reference.png\""));
            assertTrue(request.body.contains("abc"));
        }
    }
}
