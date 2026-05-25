package ai.buble.sdk.apps;

import ai.buble.sdk.BubleTimeoutException;
import ai.buble.sdk.Envelope;
import ai.buble.sdk.GenerationCanceledException;
import ai.buble.sdk.GenerationFailedException;
import ai.buble.sdk.RequestOptions;
import ai.buble.sdk.WaitOptions;
import ai.buble.sdk.generations.GenerationsService;
import ai.buble.sdk.generations.TaskStatus;
import ai.buble.sdk.http.BubleHttpClient;
import com.fasterxml.jackson.core.type.TypeReference;

import java.util.Collections;
import java.util.Map;

/**
 * Generation methods for preconfigured Buble app workflows.
 */
public final class AppGenerationsService {
    private static final TypeReference<Envelope<AppGenerationTask>> APP_GENERATION_TASK =
            new TypeReference<Envelope<AppGenerationTask>>() {};

    private final BubleHttpClient http;

    public AppGenerationsService(BubleHttpClient http) {
        this.http = http;
    }

    public Envelope<AppGenerationTask> create(String app, Map<String, Object> body) {
        return create(app, body, RequestOptions.none());
    }

    public Envelope<AppGenerationTask> create(String app, Map<String, Object> body, RequestOptions options) {
        Map<String, Object> payload = body == null ? Collections.<String, Object>emptyMap() : body;
        String path = "/api/v1/apps/" + BubleHttpClient.encodePathSegment(app) + "/generations";
        return http.post(path, payload, APP_GENERATION_TASK, options);
    }

    public Envelope<AppGenerationTask> retrieve(String app, String id) {
        return retrieve(app, id, RequestOptions.none());
    }

    public Envelope<AppGenerationTask> retrieve(String app, String id, RequestOptions options) {
        String path = "/api/v1/apps/" + BubleHttpClient.encodePathSegment(app)
                + "/generations/" + BubleHttpClient.encodePathSegment(id);
        return http.get(path, APP_GENERATION_TASK, options);
    }

    public Envelope<AppGenerationTask> wait(String app, String id) {
        return wait(app, id, WaitOptions.defaults());
    }

    public Envelope<AppGenerationTask> wait(String app, String id, WaitOptions options) {
        WaitOptions resolved = options == null ? WaitOptions.defaults() : options;
        long deadline = System.nanoTime() + resolved.getTimeout().toNanos();
        while (true) {
            Envelope<AppGenerationTask> envelope = retrieve(app, id);
            AppGenerationTask task = envelope.getData();
            if (task != null && GenerationsService.isTerminal(task.getStatus())) {
                if (task.getStatus() == TaskStatus.FAILED && resolved.isThrowOnFailed()) {
                    String message = task.getError() != null && task.getError().getMessage() != null
                            ? task.getError().getMessage()
                            : "App generation failed.";
                    throw new GenerationFailedException(message, task);
                }
                if (task.getStatus() == TaskStatus.CANCELED && resolved.isThrowOnCanceled()) {
                    throw new GenerationCanceledException("App generation " + id + " was canceled.", task);
                }
                return envelope;
            }
            if (System.nanoTime() >= deadline) {
                throw new BubleTimeoutException("App generation " + id + " did not finish within " + resolved.getTimeout() + ".", resolved.getTimeout());
            }
            GenerationsService.sleep(resolved.getInterval());
        }
    }
}
