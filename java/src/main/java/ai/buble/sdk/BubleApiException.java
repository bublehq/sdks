package ai.buble.sdk;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Raised when the Buble API returns a non-2xx response.
 */
public class BubleApiException extends BubleException {
    private final int statusCode;
    private final String code;
    private final JsonNode details;
    private final String responseBody;

    public BubleApiException(int statusCode, String code, String message, JsonNode details, String responseBody) {
        super(message);
        this.statusCode = statusCode;
        this.code = code;
        this.details = details;
        this.responseBody = responseBody;
    }

    public int getStatusCode() {
        return statusCode;
    }

    public String getCode() {
        return code;
    }

    public JsonNode getDetails() {
        return details;
    }

    public String getResponseBody() {
        return responseBody;
    }
}
