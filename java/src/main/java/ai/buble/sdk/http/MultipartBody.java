package ai.buble.sdk.http;

import ai.buble.sdk.files.FileUpload;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.io.SequenceInputStream;
import java.net.http.HttpRequest;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Internal multipart/form-data body publisher.
 */
public final class MultipartBody {
    private final String boundary;
    private final Map<String, String> fields;
    private final FileUpload file;
    private final String filename;
    private final String contentType;

    public MultipartBody(Map<String, String> fields, FileUpload file, String filename, String contentType) {
        this.boundary = "buble-sdk-" + UUID.randomUUID();
        this.fields = new LinkedHashMap<String, String>(fields);
        this.file = file;
        this.filename = filename;
        this.contentType = contentType;
    }

    public String getBoundary() {
        return boundary;
    }

    public HttpRequest.BodyPublisher toBodyPublisher() {
        return HttpRequest.BodyPublishers.ofInputStream(() -> {
            List<InputStream> streams = new ArrayList<InputStream>();
            for (Map.Entry<String, String> entry : fields.entrySet()) {
                streams.add(bytes("--" + boundary + "\r\n"));
                streams.add(bytes("Content-Disposition: form-data; name=\"" + escape(entry.getKey()) + "\"\r\n\r\n"));
                streams.add(bytes(entry.getValue() + "\r\n"));
            }
            streams.add(bytes("--" + boundary + "\r\n"));
            streams.add(bytes("Content-Disposition: form-data; name=\"file\"; filename=\"" + escape(filename) + "\"\r\n"));
            streams.add(bytes("Content-Type: " + contentType + "\r\n\r\n"));
            streams.add(file.openStream());
            streams.add(bytes("\r\n--" + boundary + "--\r\n"));
            return new SequenceInputStream(Collections.enumeration(streams));
        });
    }

    private static ByteArrayInputStream bytes(String value) {
        return new ByteArrayInputStream(value.getBytes(StandardCharsets.UTF_8));
    }

    private static String escape(String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
