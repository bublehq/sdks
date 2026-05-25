package ai.buble.sdk.generations;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Generated audio asset.
 */
public class MediaResultAudio {
    private String url;
    private String imageUrl;
    private String title;
    private JsonNode duration;

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public JsonNode getDuration() { return duration; }
    public void setDuration(JsonNode duration) { this.duration = duration; }
}
