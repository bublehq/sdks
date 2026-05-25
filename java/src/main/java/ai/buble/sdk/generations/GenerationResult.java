package ai.buble.sdk.generations;

import java.util.List;

/**
 * Generated media assets returned by a successful generation task.
 */
public class GenerationResult {
    private List<MediaResultImage> images;
    private List<MediaResultVideo> videos;
    private List<MediaResultAudio> audios;

    public List<MediaResultImage> getImages() { return images; }
    public void setImages(List<MediaResultImage> images) { this.images = images; }
    public List<MediaResultVideo> getVideos() { return videos; }
    public void setVideos(List<MediaResultVideo> videos) { this.videos = videos; }
    public List<MediaResultAudio> getAudios() { return audios; }
    public void setAudios(List<MediaResultAudio> audios) { this.audios = audios; }
}
