import ai.buble.sdk.BubleClient;
import ai.buble.sdk.Envelope;
import ai.buble.sdk.WaitOptions;
import ai.buble.sdk.generations.CreateGenerationRequest;
import ai.buble.sdk.generations.GenerationTask;

import java.time.Duration;

public class Main {
    public static void main(String[] args) {
        BubleClient client = BubleClient.fromEnv();

        Envelope<GenerationTask> task = client.generations().create(
                CreateGenerationRequest.builder()
                        .model("doubao/seedance-2.0-fast")
                        .mode("text_to_video")
                        .prompt("A slow cinematic shot of a futuristic train station at sunrise.")
                        .param("duration", "8s")
                        .param("resolution", "720p")
                        .param("aspect_ratio", "16:9")
                        .build());

        Envelope<GenerationTask> result = client.generations().wait(
                task.getData().getId(),
                WaitOptions.builder()
                        .interval(Duration.ofSeconds(2))
                        .timeout(Duration.ofMinutes(10))
                        .build());

        if (result.getData().getResult() != null
                && result.getData().getResult().getVideos() != null
                && !result.getData().getResult().getVideos().isEmpty()) {
            System.out.println(result.getData().getResult().getVideos().get(0).getUrl());
        }
    }
}
