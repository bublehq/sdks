package ai.buble.sdk.apps;

import ai.buble.sdk.generations.GenerationResult;
import ai.buble.sdk.generations.GenerationTaskError;
import ai.buble.sdk.generations.TaskStatus;

/**
 * Generation task created by a preconfigured Buble app workflow.
 */
public class AppGenerationTask {
    private String id;
    private TaskStatus status;
    private GenerationResult result;
    private GenerationTaskError error;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public TaskStatus getStatus() { return status; }
    public void setStatus(TaskStatus status) { this.status = status; }
    public GenerationResult getResult() { return result; }
    public void setResult(GenerationResult result) { this.result = result; }
    public GenerationTaskError getError() { return error; }
    public void setError(GenerationTaskError error) { this.error = error; }
}
