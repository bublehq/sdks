package ai.buble.sdk;

import java.time.Duration;

/**
 * Raised when an HTTP request or polling helper exceeds its configured timeout.
 */
public class BubleTimeoutException extends BubleException {
    private final Duration timeout;

    public BubleTimeoutException(String message, Duration timeout) {
        super(message);
        this.timeout = timeout;
    }

    public BubleTimeoutException(String message, Duration timeout, Throwable cause) {
        super(message, cause);
        this.timeout = timeout;
    }

    public Duration getTimeout() {
        return timeout;
    }
}
