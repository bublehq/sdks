package ai.buble.sdk;

/**
 * Raised when a generation request contains an internal Buble field that is not
 * accepted by the public generation API.
 */
public class UnsupportedGenerationFieldException extends BubleException {
    private final String field;

    public UnsupportedGenerationFieldException(String field) {
        super("Field \"" + field + "\" is an internal Buble field and is not supported by the public generation API.");
        this.field = field;
    }

    public String getField() {
        return field;
    }
}
