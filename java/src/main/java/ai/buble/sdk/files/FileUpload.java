package ai.buble.sdk.files;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Objects;
import java.util.function.Supplier;

/**
 * Source file for upload requests.
 */
public final class FileUpload {
    private final Supplier<InputStream> streamSupplier;
    private final String filename;
    private final String contentType;

    private FileUpload(Supplier<InputStream> streamSupplier, String filename, String contentType) {
        this.streamSupplier = streamSupplier;
        this.filename = filename;
        this.contentType = contentType;
    }

    public static FileUpload fromPath(Path path) {
        Objects.requireNonNull(path, "path");
        String filename = path.getFileName() == null ? "file" : path.getFileName().toString();
        return new FileUpload(new Supplier<InputStream>() {
            @Override
            public InputStream get() {
                try {
                    return Files.newInputStream(path);
                } catch (IOException e) {
                    throw new IllegalStateException("Failed to open upload file: " + path, e);
                }
            }
        }, filename, inferContentType(filename));
    }

    public static FileUpload fromBytes(byte[] bytes, String filename) {
        Objects.requireNonNull(bytes, "bytes");
        String resolvedFilename = filename == null || filename.isEmpty() ? "file" : filename;
        byte[] copy = bytes.clone();
        return new FileUpload(new Supplier<InputStream>() {
            @Override
            public InputStream get() {
                return new ByteArrayInputStream(copy);
            }
        }, resolvedFilename, inferContentType(resolvedFilename));
    }

    public static FileUpload fromInputStream(InputStream inputStream, String filename) {
        Objects.requireNonNull(inputStream, "inputStream");
        String resolvedFilename = filename == null || filename.isEmpty() ? "file" : filename;
        return new FileUpload(new Supplier<InputStream>() {
            @Override
            public InputStream get() {
                return inputStream;
            }
        }, resolvedFilename, inferContentType(resolvedFilename));
    }

    public InputStream openStream() {
        return streamSupplier.get();
    }

    public String getFilename() {
        return filename;
    }

    public String getContentType() {
        return contentType;
    }

    static String inferContentType(String filename) {
        String lower = filename == null ? "" : filename.toLowerCase();
        if (lower.endsWith(".png")) {
            return "image/png";
        }
        if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
            return "image/jpeg";
        }
        if (lower.endsWith(".webp")) {
            return "image/webp";
        }
        if (lower.endsWith(".gif")) {
            return "image/gif";
        }
        if (lower.endsWith(".mp4")) {
            return "video/mp4";
        }
        if (lower.endsWith(".mov")) {
            return "video/quicktime";
        }
        if (lower.endsWith(".webm")) {
            return "video/webm";
        }
        if (lower.endsWith(".mp3")) {
            return "audio/mpeg";
        }
        if (lower.endsWith(".wav")) {
            return "audio/wav";
        }
        return "application/octet-stream";
    }
}
