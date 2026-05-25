import ai.buble.sdk.BubleClient;
import ai.buble.sdk.Envelope;
import ai.buble.sdk.files.FileUpload;
import ai.buble.sdk.files.UploadOptions;
import ai.buble.sdk.files.UploadedFile;
import ai.buble.sdk.generations.CreateGenerationRequest;
import ai.buble.sdk.generations.GenerationTask;

import java.nio.file.Path;
import java.util.List;

public class Main {
    public static void main(String[] args) {
        BubleClient client = BubleClient.fromEnv();

        Envelope<UploadedFile> uploaded = client.files().upload(
                FileUpload.fromPath(Path.of("reference.png")),
                UploadOptions.builder()
                        .fileType("image")
                        .model("google/nano-banana")
                        .mode("image_to_image")
                        .build());

        Envelope<GenerationTask> task = client.generations().create(
                CreateGenerationRequest.builder()
                        .model("google/nano-banana")
                        .mode("image_to_image")
                        .prompt("Turn this reference into a polished ecommerce hero image.")
                        .imageUrls(List.of(uploaded.getData().getUrl()))
                        .build());

        System.out.println(task.getData().getId());
    }
}
