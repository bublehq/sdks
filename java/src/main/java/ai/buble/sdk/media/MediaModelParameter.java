package ai.buble.sdk.media;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;

/**
 * Public request parameter accepted by a media model operation.
 */
public class MediaModelParameter {
    private String name;
    private String type;
    private String label;
    @JsonProperty("default")
    private JsonNode defaultValue;
    @JsonProperty("enum")
    private List<JsonNode> enumValues;
    private List<JsonNode> values;
    private JsonNode min;
    private JsonNode max;
    private JsonNode step;
    private boolean required;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }
    public JsonNode getDefaultValue() { return defaultValue; }
    public void setDefaultValue(JsonNode defaultValue) { this.defaultValue = defaultValue; }
    public List<JsonNode> getEnumValues() { return enumValues; }
    public void setEnumValues(List<JsonNode> enumValues) { this.enumValues = enumValues; }
    public List<JsonNode> getValues() { return values; }
    public void setValues(List<JsonNode> values) { this.values = values; }
    public JsonNode getMin() { return min; }
    public void setMin(JsonNode min) { this.min = min; }
    public JsonNode getMax() { return max; }
    public void setMax(JsonNode max) { this.max = max; }
    public JsonNode getStep() { return step; }
    public void setStep(JsonNode step) { this.step = step; }
    public boolean isRequired() { return required; }
    public void setRequired(boolean required) { this.required = required; }
}
