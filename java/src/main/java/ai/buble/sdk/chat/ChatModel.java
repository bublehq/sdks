package ai.buble.sdk.chat;

import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;
import java.util.Map;

/**
 * Callable chat model returned by model discovery.
 */
public class ChatModel {
    private String id;
    private String object;
    private long created;
    private String ownedBy;
    private String name;
    private String description;
    private Map<String, JsonNode> capabilities;
    private List<String> tags;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getObject() { return object; }
    public void setObject(String object) { this.object = object; }
    public long getCreated() { return created; }
    public void setCreated(long created) { this.created = created; }
    public String getOwnedBy() { return ownedBy; }
    public void setOwnedBy(String ownedBy) { this.ownedBy = ownedBy; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public Map<String, JsonNode> getCapabilities() { return capabilities; }
    public void setCapabilities(Map<String, JsonNode> capabilities) { this.capabilities = capabilities; }
    public List<String> getTags() { return tags; }
    public void setTags(List<String> tags) { this.tags = tags; }
}
