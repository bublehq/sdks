package ai.buble.sdk;

/**
 * Raised when a media or app generation reaches {@code failed} status while
 * using a wait helper.
 */
public class GenerationFailedException extends BubleException {
    private final Object task;

    public GenerationFailedException(String message, Object task) {
        super(message);
        this.task = task;
    }

    public Object getTask() {
        return task;
    }
}
