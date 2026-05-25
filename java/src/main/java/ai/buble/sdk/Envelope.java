package ai.buble.sdk;

/**
 * Common response envelope used by Buble media, file, and app endpoints.
 *
 * @param <T> response data type
 */
public class Envelope<T> {
    private T data;

    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }
}
