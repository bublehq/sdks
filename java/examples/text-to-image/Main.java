import ai.buble.sdk.BubleClient;
import ai.buble.sdk.Envelope;
import ai.buble.sdk.generations.CreateGenerationRequest;
import ai.buble.sdk.generations.GenerationTask;

public class Main {
    public static void main(String[] args) {
        BubleClient client = BubleClient.fromEnv();

        Envelope<GenerationTask> task = client.generations().create(
                CreateGenerationRequest.builder()
                        .model("google/nano-banana")
                        .mode("text_to_image")
                        .prompt("A cinematic product photo of a matte black espresso cup")
                        .param("aspect_ratio", "1:1")
                        .param("output_format", "png")
                        .build());

        Envelope<GenerationTask> result = client.generations().wait(task.getData().getId());
        if (result.getData().getResult() != null
                && result.getData().getResult().getImages() != null
                && !result.getData().getResult().getImages().isEmpty()) {
            System.out.println(result.getData().getResult().getImages().get(0).getUrl());
        }
    }
}
