package ai.buble.sdk.generations;

/**
 * Task-level generation error.
 */
public class GenerationTaskError {
    private String code;
    private String message;

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
