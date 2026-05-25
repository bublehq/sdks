package ai.buble.sdk.files;

import ai.buble.sdk.Envelope;
import ai.buble.sdk.RequestOptions;
import ai.buble.sdk.http.BubleHttpClient;
import ai.buble.sdk.http.MultipartBody;
import com.fasterxml.jackson.core.type.TypeReference;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Source media upload methods.
 */
public final class FilesService {
    private static final TypeReference<Envelope<UploadedFile>> UPLOADED_FILE =
            new TypeReference<Envelope<UploadedFile>>() {};

    private final BubleHttpClient http;

    public FilesService(BubleHttpClient http) {
        this.http = http;
    }

    public Envelope<UploadedFile> upload(FileUpload file) {
        return upload(file, UploadOptions.defaults());
    }

    public Envelope<UploadedFile> upload(FileUpload file, UploadOptions options) {
        return upload(file, options, RequestOptions.none());
    }

    public Envelope<UploadedFile> upload(FileUpload file, UploadOptions options, RequestOptions requestOptions) {
        UploadOptions resolved = options == null ? UploadOptions.defaults() : options;
        Map<String, String> fields = new LinkedHashMap<String, String>();
        put(fields, "file_type", resolved.getFileType());
        put(fields, "model", resolved.getModel());
        put(fields, "mode", resolved.getMode());
        String filename = resolved.getFilename() == null || resolved.getFilename().isEmpty()
                ? file.getFilename()
                : resolved.getFilename();
        String contentType = resolved.getContentType() == null || resolved.getContentType().isEmpty()
                ? file.getContentType()
                : resolved.getContentType();
        MultipartBody body = new MultipartBody(fields, file, filename, contentType);
        return http.multipart("/api/v1/files", body, UPLOADED_FILE, requestOptions);
    }

    private static void put(Map<String, String> fields, String key, String value) {
        if (value != null && !value.isEmpty()) {
            fields.put(key, value);
        }
    }
}
