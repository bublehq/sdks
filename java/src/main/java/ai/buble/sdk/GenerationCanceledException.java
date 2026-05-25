package ai.buble.sdk;

/**
 * Raised when a media or app generation reaches {@code canceled} status while
 * using a wait helper.
 */
public class GenerationCanceledException extends BubleException {
    private final Object task;

    public GenerationCanceledException(String message, Object task) {
        super(message);
        this.task = task;
    }

    public Object getTask() {
        return task;
    }
}
