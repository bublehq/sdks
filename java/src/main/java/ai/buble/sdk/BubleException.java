package ai.buble.sdk;

/**
 * Base unchecked exception for errors raised by the Buble Java SDK.
 */
public class BubleException extends RuntimeException {
    public BubleException(String message) {
        super(message);
    }

    public BubleException(String message, Throwable cause) {
        super(message, cause);
    }
}
