package ai.buble.sdk;

import java.time.Duration;

/**
 * Polling options for asynchronous media and app generation tasks.
 */
public final class WaitOptions {
    private final Duration interval;
    private final Duration timeout;
    private final boolean throwOnFailed;
    private final boolean throwOnCanceled;

    private WaitOptions(Builder builder) {
        this.interval = builder.interval;
        this.timeout = builder.timeout;
        this.throwOnFailed = builder.throwOnFailed;
        this.throwOnCanceled = builder.throwOnCanceled;
    }

    public static WaitOptions defaults() {
        return builder().build();
    }

    public static Builder builder() {
        return new Builder();
    }

    public Duration getInterval() {
        return interval;
    }

    public Duration getTimeout() {
        return timeout;
    }

    public boolean isThrowOnFailed() {
        return throwOnFailed;
    }

    public boolean isThrowOnCanceled() {
        return throwOnCanceled;
    }

    public static final class Builder {
        private Duration interval = Duration.ofSeconds(2);
        private Duration timeout = Duration.ofMinutes(10);
        private boolean throwOnFailed = true;
        private boolean throwOnCanceled = true;

        public Builder interval(Duration interval) {
            if (interval != null) {
                this.interval = interval;
            }
            return this;
        }

        public Builder timeout(Duration timeout) {
            if (timeout != null) {
                this.timeout = timeout;
            }
            return this;
        }

        public Builder throwOnFailed(boolean throwOnFailed) {
            this.throwOnFailed = throwOnFailed;
            return this;
        }

        public Builder throwOnCanceled(boolean throwOnCanceled) {
            this.throwOnCanceled = throwOnCanceled;
            return this;
        }

        public WaitOptions build() {
            return new WaitOptions(this);
        }
    }
}
