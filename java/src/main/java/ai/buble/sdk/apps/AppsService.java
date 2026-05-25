package ai.buble.sdk.apps;

import ai.buble.sdk.Envelope;
import ai.buble.sdk.RequestOptions;
import ai.buble.sdk.http.BubleHttpClient;
import com.fasterxml.jackson.core.type.TypeReference;

import java.util.List;

/**
 * Buble app workflow discovery and generation methods.
 */
public final class AppsService {
    private static final TypeReference<Envelope<List<PublicApp>>> APP_LIST =
            new TypeReference<Envelope<List<PublicApp>>>() {};
    private static final TypeReference<Envelope<PublicApp>> APP =
            new TypeReference<Envelope<PublicApp>>() {};

    private final BubleHttpClient http;
    private final AppGenerationsService generations;

    public AppsService(BubleHttpClient http) {
        this.http = http;
        this.generations = new AppGenerationsService(http);
    }

    public Envelope<List<PublicApp>> list() {
        return list(0, 0);
    }

    public Envelope<List<PublicApp>> list(int page, int limit) {
        RequestOptions.Builder options = RequestOptions.builder();
        if (page > 0) {
            options.query("page", Integer.toString(page));
        }
        if (limit > 0) {
            options.query("limit", Integer.toString(limit));
        }
        return http.get("/api/v1/apps", APP_LIST, options.build());
    }

    public Envelope<PublicApp> retrieve(String app) {
        return http.get("/api/v1/apps/" + BubleHttpClient.encodePathSegment(app), APP);
    }

    public AppGenerationsService generations() {
        return generations;
    }
}
