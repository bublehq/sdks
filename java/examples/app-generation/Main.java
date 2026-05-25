import ai.buble.sdk.BubleClient;
import ai.buble.sdk.Envelope;
import ai.buble.sdk.apps.AppGenerationTask;

import java.util.List;
import java.util.Map;

public class Main {
    public static void main(String[] args) {
        BubleClient client = BubleClient.fromEnv();

        Envelope<AppGenerationTask> task = client.apps().generations().create(
                "video-background-remover",
                Map.of(
                        "source_video", List.of("https://example.com/source.mp4"),
                        "refine_foreground_edges", true,
                        "subject_is_person", true
                ));

        Envelope<AppGenerationTask> result = client.apps().generations().wait(
                "video-background-remover",
                task.getData().getId());

        System.out.println(result.getData().getStatus().getValue());
    }
}
