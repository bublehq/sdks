package ai.buble.sdk;

import ai.buble.sdk.apps.AppsService;
import ai.buble.sdk.chat.ChatService;
import ai.buble.sdk.files.FilesService;
import ai.buble.sdk.generations.GenerationsService;
import ai.buble.sdk.http.BubleHttpClient;
import ai.buble.sdk.media.MediaModelsService;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;

import java.net.http.HttpClient;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Server-side client for the Buble public API.
 */
public final class BubleClient {
    public static final String DEFAULT_BASE_URL = "https://buble.ai";
    public static final Duration DEFAULT_TIMEOUT = Duration.ofSeconds(60);

    private final BubleHttpClient http;
    private final MediaModelsService mediaModels;
    private final FilesService files;
    private final GenerationsService generations;
    private final AppsService apps;
    private final ChatService chat;

    private BubleClient(Builder builder) {
        String resolvedApiKey = firstNonEmpty(builder.apiKey, System.getenv("BUBLE_API_KEY"));
        String resolvedBaseUrl = firstNonEmpty(builder.baseUrl, System.getenv("BUBLE_BASE_URL"), DEFAULT_BASE_URL);
        if (resolvedApiKey == null || resolvedApiKey.isEmpty()) {
            throw new BubleException("Missing Buble API key. Pass apiKey or set BUBLE_API_KEY.");
        }
        ObjectMapper mapper = builder.objectMapper == null ? defaultObjectMapper() : builder.objectMapper;
        this.http = new BubleHttpClient(
                resolvedApiKey,
                resolvedBaseUrl,
                builder.timeout,
                builder.httpClient,
                mapper,
                builder.headers
        );
        this.mediaModels = new MediaModelsService(http);
        this.files = new FilesService(http);
        this.generations = new GenerationsService(http);
        this.apps = new AppsService(http);
        this.chat = new ChatService(http);
    }

    public static BubleClient fromEnv() {
        return builder().build();
    }

    public static Builder builder() {
        return new Builder();
    }

    public String getBaseUrl() {
        return http.getBaseUrl();
    }

    public MediaModelsService mediaModels() {
        return mediaModels;
    }

    public FilesService files() {
        return files;
    }

    public GenerationsService generations() {
        return generations;
    }

    public AppsService apps() {
        return apps;
    }

    public ChatService chat() {
        return chat;
    }

    private static ObjectMapper defaultObjectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.setPropertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
        mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        return mapper;
    }

    private static String firstNonEmpty(String... values) {
        for (String value : values) {
            if (value != null && !value.isEmpty()) {
                return value;
            }
        }
        return null;
    }

    public static final class Builder {
        private String apiKey;
        private String baseUrl;
        private Duration timeout = DEFAULT_TIMEOUT;
        private HttpClient httpClient = HttpClient.newHttpClient();
        private ObjectMapper objectMapper;
        private final Map<String, String> headers = new LinkedHashMap<String, String>();

        public Builder apiKey(String apiKey) {
            this.apiKey = apiKey;
            return this;
        }

        public Builder baseUrl(String baseUrl) {
            this.baseUrl = baseUrl;
            return this;
        }

        public Builder timeout(Duration timeout) {
            if (timeout != null) {
                this.timeout = timeout;
            }
            return this;
        }

        public Builder httpClient(HttpClient httpClient) {
            if (httpClient != null) {
                this.httpClient = httpClient;
            }
            return this;
        }

        public Builder objectMapper(ObjectMapper objectMapper) {
            this.objectMapper = objectMapper;
            return this;
        }

        public Builder header(String key, String value) {
            if (key != null && value != null) {
                this.headers.put(key, value);
            }
            return this;
        }

        public BubleClient build() {
            return new BubleClient(this);
        }
    }
}
