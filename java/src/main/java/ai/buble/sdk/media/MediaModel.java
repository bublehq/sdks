package ai.buble.sdk.media;

import java.util.List;

/**
 * API-ready media model returned by media model discovery.
 */
public class MediaModel {
    private String model;
    private String name;
    private String mediaType;
    private List<MediaModelOperation> operations;

    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getMediaType() { return mediaType; }
    public void setMediaType(String mediaType) { this.mediaType = mediaType; }
    public List<MediaModelOperation> getOperations() { return operations; }
    public void setOperations(List<MediaModelOperation> operations) { this.operations = operations; }
}
