package ai.buble.sdk.generations;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Generated video asset.
 */
public class MediaResultVideo {
    private String url;
    private String previewUrl;
    private String thumbnailUrl;
    private JsonNode duration;

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }
    public String getPreviewUrl() { return previewUrl; }
    public void setPreviewUrl(String previewUrl) { this.previewUrl = previewUrl; }
    public String getThumbnailUrl() { return thumbnailUrl; }
    public void setThumbnailUrl(String thumbnailUrl) { this.thumbnailUrl = thumbnailUrl; }
    public JsonNode getDuration() { return duration; }
    public void setDuration(JsonNode duration) { this.duration = duration; }
}
