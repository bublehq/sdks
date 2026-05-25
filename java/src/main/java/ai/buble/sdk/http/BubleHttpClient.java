package ai.buble.sdk.http;

import ai.buble.sdk.BubleApiException;
import ai.buble.sdk.BubleException;
import ai.buble.sdk.BubleTimeoutException;
import ai.buble.sdk.RequestOptions;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Internal HTTP adapter used by SDK resources.
 */
public final class BubleHttpClient {
    private final String apiKey;
    private final String baseUrl;
    private final Duration timeout;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;
    private final Map<String, String> headers;

    public BubleHttpClient(
            String apiKey,
            String baseUrl,
            Duration timeout,
            HttpClient httpClient,
            ObjectMapper objectMapper,
            Map<String, String> headers
    ) {
        this.apiKey = apiKey;
        this.baseUrl = trimTrailingSlash(baseUrl);
        this.timeout = timeout;
        this.httpClient = httpClient;
        this.objectMapper = objectMapper;
        this.headers = Collections.unmodifiableMap(new LinkedHashMap<String, String>(headers));
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public ObjectMapper getObjectMapper() {
        return objectMapper;
    }

    public <T> T get(String path, TypeReference<T> type) {
        return request("GET", path, null, type, RequestOptions.none());
    }

    public <T> T get(String path, TypeReference<T> type, RequestOptions options) {
        return request("GET", path, null, type, options);
    }

    public <T> T post(String path, Object body, TypeReference<T> type) {
        return request("POST", path, body, type, RequestOptions.none());
    }

    public <T> T post(String path, Object body, TypeReference<T> type, RequestOptions options) {
        return request("POST", path, body, type, options);
    }

    public HttpResponse<InputStream> stream(String path, Object body, RequestOptions options) {
        byte[] json = encodeJson(body == null ? Collections.emptyMap() : body);
        HttpRequest request = baseRequest(path, options)
                .header("Content-Type", "application/json")
                .setHeader("Accept", "text/event-stream")
                .POST(HttpRequest.BodyPublishers.ofByteArray(json))
                .build();
        return sendStream(request);
    }

    public <T> T multipart(String path, MultipartBody body, TypeReference<T> type, RequestOptions options) {
        HttpRequest request = baseRequest(path, options)
                .header("Content-Type", "multipart/form-data; boundary=" + body.getBoundary())
                .POST(body.toBodyPublisher())
                .build();
        HttpResponse<String> response = send(request);
        return parseSuccessful(response, type);
    }

    private <T> T request(String method, String path, Object body, TypeReference<T> type, RequestOptions options) {
        HttpRequest.BodyPublisher publisher;
        HttpRequest.Builder builder = baseRequest(path, options);

        if (body == null) {
            publisher = HttpRequest.BodyPublishers.noBody();
        } else {
            publisher = HttpRequest.BodyPublishers.ofByteArray(encodeJson(body));
            builder.header("Content-Type", "application/json");
        }

        HttpRequest request = builder.method(method, publisher).build();
        HttpResponse<String> response = send(request);
        return parseSuccessful(response, type);
    }

    private HttpRequest.Builder baseRequest(String path, RequestOptions options) {
        if (apiKey == null || apiKey.isEmpty()) {
            throw new BubleException("Missing Buble API key. Pass apiKey or set BUBLE_API_KEY.");
        }
        RequestOptions resolved = options == null ? RequestOptions.none() : options;
        HttpRequest.Builder builder = HttpRequest.newBuilder(resolve(path, resolved.getQuery()))
                .timeout(timeout)
                .header("Authorization", "Bearer " + apiKey)
                .header("Accept", "application/json");
        for (Map.Entry<String, String> entry : headers.entrySet()) {
            builder.header(entry.getKey(), entry.getValue());
        }
        for (Map.Entry<String, String> entry : resolved.getHeaders().entrySet()) {
            builder.setHeader(entry.getKey(), entry.getValue());
        }
        return builder;
    }

    private HttpResponse<String> send(HttpRequest request) {
        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw apiException(response.statusCode(), response.body());
            }
            return response;
        } catch (java.net.http.HttpTimeoutException e) {
            throw new BubleTimeoutException("Buble API request timed out after " + timeout + ".", timeout, e);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new BubleException("Buble API request was interrupted.", e);
        }
    }

    private HttpResponse<InputStream> sendStream(HttpRequest request) {
        try {
            HttpResponse<InputStream> response = httpClient.send(request, HttpResponse.BodyHandlers.ofInputStream());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                String responseBody = new String(response.body().readAllBytes(), StandardCharsets.UTF_8);
                throw apiException(response.statusCode(), responseBody);
            }
            return response;
        } catch (java.net.http.HttpTimeoutException e) {
            throw new BubleTimeoutException("Buble API request timed out after " + timeout + ".", timeout, e);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new BubleException("Buble API request was interrupted.", e);
        }
    }

    private <T> T parseSuccessful(HttpResponse<String> response, TypeReference<T> type) {
        if (response.statusCode() == 204 || type == null || response.body() == null || response.body().isEmpty()) {
            return null;
        }
        try {
            return objectMapper.readValue(response.body(), type);
        } catch (JsonProcessingException e) {
            throw new BubleException("Failed to parse Buble API response.", e);
        }
    }

    private byte[] encodeJson(Object body) {
        try {
            return objectMapper.writeValueAsBytes(body);
        } catch (JsonProcessingException e) {
            throw new BubleException("Failed to encode Buble API request body.", e);
        }
    }

    private BubleApiException apiException(int statusCode, String responseBody) {
        String message = responseBody;
        String code = null;
        JsonNode details = null;
        if (message == null || message.isEmpty()) {
            message = "Buble API request failed with status " + statusCode + ".";
        }
        try {
            JsonNode root = objectMapper.readTree(responseBody);
            JsonNode error = root.path("error");
            if (error.isObject()) {
                if (error.hasNonNull("message")) {
                    message = error.get("message").asText();
                }
                if (error.hasNonNull("code")) {
                    code = error.get("code").asText();
                }
                if (error.has("details")) {
                    details = error.get("details");
                }
            }
        } catch (Exception ignored) {
            // Use the raw response body when the server did not return JSON.
        }
        return new BubleApiException(statusCode, code, message, details, responseBody);
    }

    private URI resolve(String path, Map<String, String> query) {
        String normalizedPath = path.startsWith("/") ? path : "/" + path;
        StringBuilder url = new StringBuilder(baseUrl).append(normalizedPath);
        boolean hasQuery = normalizedPath.contains("?");
        for (Map.Entry<String, String> entry : query.entrySet()) {
            url.append(hasQuery ? '&' : '?');
            hasQuery = true;
            url.append(urlEncode(entry.getKey())).append('=').append(urlEncode(entry.getValue()));
        }
        return URI.create(url.toString());
    }

    public static String encodePathSegment(String value) {
        return urlEncode(value);
    }

    public static String encodeModelPath(String model) {
        String[] parts = model.split("/", -1);
        StringBuilder encoded = new StringBuilder();
        for (int i = 0; i < parts.length; i++) {
            if (i > 0) {
                encoded.append('/');
            }
            encoded.append(urlEncode(parts[i]));
        }
        return encoded.toString();
    }

    private static String urlEncode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8).replace("+", "%20");
    }

    private static String trimTrailingSlash(String value) {
        String out = value == null || value.isEmpty() ? "https://buble.ai" : value;
        while (out.endsWith("/")) {
            out = out.substring(0, out.length() - 1);
        }
        return out;
    }
}
