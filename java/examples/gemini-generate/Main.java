import ai.buble.sdk.BubleClient;
import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;
import java.util.Map;

public class Main {
    public static void main(String[] args) {
        BubleClient client = BubleClient.fromEnv();

        Map<String, JsonNode> response = client.chat().gemini().generateContent(
                "google/gemini-2.5-flash",
                Map.of("contents", List.of(
                        Map.of("role", "user", "parts", List.of(Map.of("text", "Write one concise sentence.")))
                )));

        System.out.println(response);
    }
}
