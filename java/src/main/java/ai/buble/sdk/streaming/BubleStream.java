package ai.buble.sdk.streaming;

import ai.buble.sdk.BubleException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

/**
 * Closeable iterator over server-sent events returned by chat streaming APIs.
 */
public final class BubleStream implements AutoCloseable {
    private final BufferedReader reader;
    private final ObjectMapper objectMapper;
    private final StreamProtocol protocol;
    private SseEvent event;
    private boolean closed;

    public BubleStream(InputStream inputStream, ObjectMapper objectMapper, StreamProtocol protocol) {
        this.reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8));
        this.objectMapper = objectMapper;
        this.protocol = protocol;
    }

    public boolean next() {
        if (closed) {
            return false;
        }
        try {
            String line;
            String eventName = null;
            StringBuilder data = new StringBuilder();
            while ((line = reader.readLine()) != null) {
                if (line.isEmpty()) {
                    if (data.length() == 0) {
                        continue;
                    }
                    String payload = data.toString();
                    if ("[DONE]".equals(payload)) {
                        close();
                        return false;
                    }
                    JsonNode json = null;
                    try {
                        json = objectMapper.readTree(payload);
                    } catch (Exception ignored) {
                        // Preserve non-JSON data for callers through getEvent().
                    }
                    event = new SseEvent(eventName, payload, json);
                    return true;
                }
                if (line.startsWith("event:")) {
                    eventName = line.substring("event:".length()).trim();
                } else if (line.startsWith("data:")) {
                    if (data.length() > 0) {
                        data.append('\n');
                    }
                    data.append(line.substring("data:".length()).trim());
                }
            }
            close();
            return false;
        } catch (IOException e) {
            throw new BubleException("Failed while reading Buble stream.", e);
        }
    }

    public SseEvent getEvent() {
        return event;
    }

    public String text() {
        if (event == null || event.getJson() == null) {
            return "";
        }
        if (protocol == StreamProtocol.OPENAI) {
            return openAIText(event.getJson());
        }
        if (protocol == StreamProtocol.ANTHROPIC) {
            return anthropicText(event.getJson());
        }
        if (protocol == StreamProtocol.GEMINI) {
            return geminiText(event.getJson());
        }
        return "";
    }

    private static String openAIText(JsonNode json) {
        JsonNode choices = json.path("choices");
        if (choices.isArray() && choices.size() > 0) {
            JsonNode content = choices.get(0).path("delta").path("content");
            if (content.isTextual()) {
                return content.asText();
            }
        }
        return "";
    }

    private static String anthropicText(JsonNode json) {
        JsonNode deltaText = json.path("delta").path("text");
        if (deltaText.isTextual()) {
            return deltaText.asText();
        }
        JsonNode text = json.path("text");
        if (text.isTextual()) {
            return text.asText();
        }
        return "";
    }

    private static String geminiText(JsonNode json) {
        JsonNode candidates = json.path("candidates");
        if (!candidates.isArray()) {
            return "";
        }
        StringBuilder out = new StringBuilder();
        for (JsonNode candidate : candidates) {
            JsonNode parts = candidate.path("content").path("parts");
            if (parts.isArray()) {
                for (JsonNode part : parts) {
                    JsonNode text = part.path("text");
                    if (text.isTextual()) {
                        out.append(text.asText());
                    }
                }
            }
        }
        return out.toString();
    }

    @Override
    public void close() {
        if (closed) {
            return;
        }
        closed = true;
        try {
            reader.close();
        } catch (IOException e) {
            throw new BubleException("Failed to close Buble stream.", e);
        }
    }
}
