package ai.buble.sdk.streaming;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * One server-sent event from a streaming chat endpoint.
 */
public final class SseEvent {
    private final String event;
    private final String data;
    private final JsonNode json;

    public SseEvent(String event, String data, JsonNode json) {
        this.event = event;
        this.data = data;
        this.json = json;
    }

    public String getEvent() {
        return event;
    }

    public String getData() {
        return data;
    }

    public JsonNode getJson() {
        return json;
    }
}
