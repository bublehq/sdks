package ai.buble.sdk;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

final class BubleClientTest {
    @Test
    void sendsAuthorizationAndParsesApiErrors() throws Exception {
        try (TestHttpServer server = new TestHttpServer(request ->
                new TestHttpServer.Response(401, "{\"error\":{\"code\":\"invalid_api_key\",\"message\":\"Bad key\",\"details\":{\"reason\":\"test\"}}}"))) {
            BubleClient client = BubleClient.builder()
                    .apiKey("sk_test")
                    .baseUrl(server.url())
                    .build();

            BubleApiException error = assertThrows(BubleApiException.class, () -> client.mediaModels().list());

            assertEquals(401, error.getStatusCode());
            assertEquals("invalid_api_key", error.getCode());
            assertEquals("Bad key", error.getMessage());
            assertEquals("Bearer sk_test", server.requests().get(0).authorization);
        }
    }
}
