package ai.buble.sdk.files;

/**
 * Optional metadata for Buble file upload requests.
 */
public final class UploadOptions {
    private final String fileType;
    private final String model;
    private final String mode;
    private final String filename;
    private final String contentType;

    private UploadOptions(Builder builder) {
        this.fileType = builder.fileType;
        this.model = builder.model;
        this.mode = builder.mode;
        this.filename = builder.filename;
        this.contentType = builder.contentType;
    }

    public static UploadOptions defaults() {
        return builder().build();
    }

    public static Builder builder() {
        return new Builder();
    }

    public String getFileType() {
        return fileType;
    }

    public String getModel() {
        return model;
    }

    public String getMode() {
        return mode;
    }

    public String getFilename() {
        return filename;
    }

    public String getContentType() {
        return contentType;
    }

    public static final class Builder {
        private String fileType;
        private String model;
        private String mode;
        private String filename;
        private String contentType;

        public Builder fileType(String fileType) {
            this.fileType = fileType;
            return this;
        }

        public Builder model(String model) {
            this.model = model;
            return this;
        }

        public Builder mode(String mode) {
            this.mode = mode;
            return this;
        }

        public Builder filename(String filename) {
            this.filename = filename;
            return this;
        }

        public Builder contentType(String contentType) {
            this.contentType = contentType;
            return this;
        }

        public UploadOptions build() {
            return new UploadOptions(this);
        }
    }
}
