package ai.buble.sdk.generations;

/**
 * Direct media generation task.
 */
public class GenerationTask {
    private String id;
    private TaskStatus status;
    private String model;
    private String mediaType;
    private String mode;
    private int costCredits;
    private String createdAt;
    private String updatedAt;
    private GenerationResult result;
    private GenerationTaskError error;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public TaskStatus getStatus() { return status; }
    public void setStatus(TaskStatus status) { this.status = status; }
    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }
    public String getMediaType() { return mediaType; }
    public void setMediaType(String mediaType) { this.mediaType = mediaType; }
    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }
    public int getCostCredits() { return costCredits; }
    public void setCostCredits(int costCredits) { this.costCredits = costCredits; }
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
    public String getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(String updatedAt) { this.updatedAt = updatedAt; }
    public GenerationResult getResult() { return result; }
    public void setResult(GenerationResult result) { this.result = result; }
    public GenerationTaskError getError() { return error; }
    public void setError(GenerationTaskError error) { this.error = error; }
}
