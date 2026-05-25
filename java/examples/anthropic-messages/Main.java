import ai.buble.sdk.BubleClient;
import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;
import java.util.Map;

public class Main {
    public static void main(String[] args) {
        BubleClient client = BubleClient.fromEnv();

        Map<String, JsonNode> message = client.chat().messages().create(Map.of(
                "model", "openai/gpt-5.5",
                "system", "You are concise.",
                "messages", List.of(Map.of("role", "user", "content", "Summarize this release.")),
                "max_tokens", 800
        ));

        System.out.println(message);
    }
}
