package ai.buble.sdk.generations;

import ai.buble.sdk.UnsupportedGenerationFieldException;

import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Request body for asynchronous media generation.
 *
 * <p>Buble's public generation API uses a flat JSON object. Stable fields are
 * represented directly on this type; model-specific parameters should be added
 * with {@link Builder#param(String, Object)} and are serialized at the JSON root.</p>
 */
public final class CreateGenerationRequest {
    private static final Set<String> FORBIDDEN_FIELDS = Collections.unmodifiableSet(new LinkedHashSet<String>(Arrays.asList(
            "input",
            "options",
            "scene",
            "sub_mode_id",
            "subModeId",
            "provider",
            "mediaType",
            "media_type",
            "images",
            "image_input",
            "video_input",
            "audio_input"
    )));

    private final String model;
    private final String mode;
    private final String prompt;
    private final List<String> imageUrls;
    private final String startFrame;
    private final String endFrame;
    private final List<String> videoUrls;
    private final List<String> audioUrls;
    private final Boolean isPublic;
    private final Boolean copyProtected;
    private final Map<String, Object> params;

    private CreateGenerationRequest(Builder builder) {
        this.model = builder.model;
        this.mode = builder.mode;
        this.prompt = builder.prompt;
        this.imageUrls = builder.imageUrls;
        this.startFrame = builder.startFrame;
        this.endFrame = builder.endFrame;
        this.videoUrls = builder.videoUrls;
        this.audioUrls = builder.audioUrls;
        this.isPublic = builder.isPublic;
        this.copyProtected = builder.copyProtected;
        this.params = Collections.unmodifiableMap(new LinkedHashMap<String, Object>(builder.params));
    }

    public static Builder builder() {
        return new Builder();
    }

    public Map<String, Object> toRequestBody() {
        Map<String, Object> body = new LinkedHashMap<String, Object>();
        put(body, "model", model);
        put(body, "mode", mode);
        put(body, "prompt", prompt);
        put(body, "image_urls", imageUrls);
        put(body, "start_frame", startFrame);
        put(body, "end_frame", endFrame);
        put(body, "video_urls", videoUrls);
        put(body, "audio_urls", audioUrls);
        put(body, "is_public", isPublic);
        put(body, "copy_protected", copyProtected);
        for (Map.Entry<String, Object> entry : params.entrySet()) {
            if (entry.getValue() == null) {
                continue;
            }
            if (FORBIDDEN_FIELDS.contains(entry.getKey())) {
                throw new UnsupportedGenerationFieldException(entry.getKey());
            }
            body.put(entry.getKey(), entry.getValue());
        }
        for (String key : body.keySet()) {
            if (FORBIDDEN_FIELDS.contains(key)) {
                throw new UnsupportedGenerationFieldException(key);
            }
        }
        return body;
    }

    private static void put(Map<String, Object> body, String key, Object value) {
        if (value == null) {
            return;
        }
        if (value instanceof String && ((String) value).isEmpty()) {
            return;
        }
        if (value instanceof List && ((List<?>) value).isEmpty()) {
            return;
        }
        body.put(key, value);
    }

    public static final class Builder {
        private String model;
        private String mode;
        private String prompt;
        private List<String> imageUrls;
        private String startFrame;
        private String endFrame;
        private List<String> videoUrls;
        private List<String> audioUrls;
        private Boolean isPublic;
        private Boolean copyProtected;
        private final Map<String, Object> params = new LinkedHashMap<String, Object>();

        public Builder model(String model) { this.model = model; return this; }
        public Builder mode(String mode) { this.mode = mode; return this; }
        public Builder prompt(String prompt) { this.prompt = prompt; return this; }
        public Builder imageUrls(List<String> imageUrls) { this.imageUrls = imageUrls; return this; }
        public Builder startFrame(String startFrame) { this.startFrame = startFrame; return this; }
        public Builder endFrame(String endFrame) { this.endFrame = endFrame; return this; }
        public Builder videoUrls(List<String> videoUrls) { this.videoUrls = videoUrls; return this; }
        public Builder audioUrls(List<String> audioUrls) { this.audioUrls = audioUrls; return this; }
        public Builder isPublic(Boolean isPublic) { this.isPublic = isPublic; return this; }
        public Builder copyProtected(Boolean copyProtected) { this.copyProtected = copyProtected; return this; }

        public Builder param(String key, Object value) {
            if (FORBIDDEN_FIELDS.contains(key)) {
                throw new UnsupportedGenerationFieldException(key);
            }
            this.params.put(key, value);
            return this;
        }

        public Builder params(Map<String, ?> params) {
            if (params != null) {
                for (Map.Entry<String, ?> entry : params.entrySet()) {
                    param(entry.getKey(), entry.getValue());
                }
            }
            return this;
        }

        public CreateGenerationRequest build() {
            return new CreateGenerationRequest(this);
        }
    }
}
