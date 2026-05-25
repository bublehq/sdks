import ai.buble.sdk.BubleClient;
import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;
import java.util.Map;

public class Main {
    public static void main(String[] args) {
        BubleClient client = BubleClient.fromEnv();

        Map<String, JsonNode> completion = client.chat().completions().create(Map.of(
                "model", "openai/gpt-5.5",
                "messages", List.of(Map.of("role", "user", "content", "Write a short launch summary.")),
                "max_completion_tokens", 800
        ));

        System.out.println(completion);
    }
}
