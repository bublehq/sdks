package ai.buble.sdk.generations;

import ai.buble.sdk.BubleException;
import ai.buble.sdk.BubleTimeoutException;
import ai.buble.sdk.Envelope;
import ai.buble.sdk.GenerationCanceledException;
import ai.buble.sdk.GenerationFailedException;
import ai.buble.sdk.RequestOptions;
import ai.buble.sdk.WaitOptions;
import ai.buble.sdk.http.BubleHttpClient;
import com.fasterxml.jackson.core.type.TypeReference;

import java.time.Duration;

/**
 * Direct media generation methods.
 */
public final class GenerationsService {
    private static final TypeReference<Envelope<GenerationTask>> GENERATION_TASK =
            new TypeReference<Envelope<GenerationTask>>() {};

    private final BubleHttpClient http;

    public GenerationsService(BubleHttpClient http) {
        this.http = http;
    }

    public Envelope<GenerationTask> create(CreateGenerationRequest request) {
        return create(request, RequestOptions.none());
    }

    public Envelope<GenerationTask> create(CreateGenerationRequest request, RequestOptions options) {
        if (request == null) {
            throw new BubleException("Generation request is required.");
        }
        return http.post("/api/v1/generations", request.toRequestBody(), GENERATION_TASK, options);
    }

    public Envelope<GenerationTask> retrieve(String id) {
        return retrieve(id, RequestOptions.none());
    }

    public Envelope<GenerationTask> retrieve(String id, RequestOptions options) {
        return http.get("/api/v1/generations/" + BubleHttpClient.encodePathSegment(id), GENERATION_TASK, options);
    }

    public Envelope<GenerationTask> wait(String id) {
        return wait(id, WaitOptions.defaults());
    }

    public Envelope<GenerationTask> wait(String id, WaitOptions options) {
        WaitOptions resolved = options == null ? WaitOptions.defaults() : options;
        long deadline = System.nanoTime() + resolved.getTimeout().toNanos();
        while (true) {
            Envelope<GenerationTask> envelope = retrieve(id);
            GenerationTask task = envelope.getData();
            if (task != null && isTerminal(task.getStatus())) {
                if (task.getStatus() == TaskStatus.FAILED && resolved.isThrowOnFailed()) {
                    throw new GenerationFailedException(errorMessage(task, "Generation failed."), task);
                }
                if (task.getStatus() == TaskStatus.CANCELED && resolved.isThrowOnCanceled()) {
                    throw new GenerationCanceledException("Generation " + id + " was canceled.", task);
                }
                return envelope;
            }
            if (System.nanoTime() >= deadline) {
                throw new BubleTimeoutException("Generation " + id + " did not finish within " + resolved.getTimeout() + ".", resolved.getTimeout());
            }
            sleep(resolved.getInterval());
        }
    }

    public static boolean isTerminal(TaskStatus status) {
        return status == TaskStatus.SUCCESS || status == TaskStatus.FAILED || status == TaskStatus.CANCELED;
    }

    static String errorMessage(GenerationTask task, String fallback) {
        if (task != null && task.getError() != null && task.getError().getMessage() != null && !task.getError().getMessage().isEmpty()) {
            return task.getError().getMessage();
        }
        return fallback;
    }

    public static void sleep(Duration duration) {
        try {
            Thread.sleep(duration.toMillis());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new BubleException("Generation wait was interrupted.", e);
        }
    }
}
