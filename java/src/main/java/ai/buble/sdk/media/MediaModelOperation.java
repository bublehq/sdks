package ai.buble.sdk.media;

import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;
import java.util.Map;

/**
 * Public operation mode supported by a Buble media model.
 */
public class MediaModelOperation {
    private String mode;
    private String description;
    private Map<String, JsonNode> input;
    private List<MediaModelParameter> parameters;

    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public Map<String, JsonNode> getInput() { return input; }
    public void setInput(Map<String, JsonNode> input) { this.input = input; }
    public List<MediaModelParameter> getParameters() { return parameters; }
    public void setParameters(List<MediaModelParameter> parameters) { this.parameters = parameters; }
}
