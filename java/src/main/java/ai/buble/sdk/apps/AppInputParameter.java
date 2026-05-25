package ai.buble.sdk.apps;

import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;

/**
 * Flat input parameter accepted by a Buble app workflow.
 */
public class AppInputParameter {
    private String name;
    private String type;
    private List<JsonNode> values;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public List<JsonNode> getValues() { return values; }
    public void setValues(List<JsonNode> values) { this.values = values; }
}
