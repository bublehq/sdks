package ai.buble.sdk;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Optional per-request headers and query parameters.
 */
public final class RequestOptions {
    private static final RequestOptions EMPTY = builder().build();

    private final Map<String, String> headers;
    private final Map<String, String> query;

    private RequestOptions(Builder builder) {
        this.headers = Collections.unmodifiableMap(new LinkedHashMap<String, String>(builder.headers));
        this.query = Collections.unmodifiableMap(new LinkedHashMap<String, String>(builder.query));
    }

    public static RequestOptions none() {
        return EMPTY;
    }

    public static Builder builder() {
        return new Builder();
    }

    public Map<String, String> getHeaders() {
        return headers;
    }

    public Map<String, String> getQuery() {
        return query;
    }

    public static final class Builder {
        private final Map<String, String> headers = new LinkedHashMap<String, String>();
        private final Map<String, String> query = new LinkedHashMap<String, String>();

        public Builder header(String key, String value) {
            if (key != null && value != null) {
                headers.put(key, value);
            }
            return this;
        }

        public Builder query(String key, String value) {
            if (key != null && value != null) {
                query.put(key, value);
            }
            return this;
        }

        public RequestOptions build() {
            return new RequestOptions(this);
        }
    }
}
