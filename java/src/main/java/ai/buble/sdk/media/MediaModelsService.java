package ai.buble.sdk.media;

import ai.buble.sdk.Envelope;
import ai.buble.sdk.RequestOptions;
import ai.buble.sdk.http.BubleHttpClient;
import com.fasterxml.jackson.core.type.TypeReference;

import java.util.List;

/**
 * Media model discovery methods.
 */
public final class MediaModelsService {
    private static final TypeReference<Envelope<List<MediaModel>>> MEDIA_MODEL_LIST =
            new TypeReference<Envelope<List<MediaModel>>>() {};

    private final BubleHttpClient http;

    public MediaModelsService(BubleHttpClient http) {
        this.http = http;
    }

    public Envelope<List<MediaModel>> list() {
        return http.get("/api/v1/media_models", MEDIA_MODEL_LIST);
    }

    public Envelope<List<MediaModel>> list(String mediaType) {
        RequestOptions.Builder options = RequestOptions.builder();
        if (mediaType != null && !mediaType.isEmpty()) {
            options.query("media_type", mediaType);
        }
        return http.get("/api/v1/media_models", MEDIA_MODEL_LIST, options.build());
    }
}
