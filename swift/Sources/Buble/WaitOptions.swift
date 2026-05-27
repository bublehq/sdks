/// Polling options for generation wait helpers.
public struct WaitOptions: Sendable {
    public var interval: TimeInterval
    public var timeout: TimeInterval
    public var throwOnFailed: Bool
    public var throwOnCanceled: Bool

    public init(
        interval: TimeInterval = 2,
        timeout: TimeInterval = 600,
        throwOnFailed: Bool = true,
        throwOnCanceled: Bool = true
    ) {
        self.interval = interval
        self.timeout = timeout
        self.throwOnFailed = throwOnFailed
        self.throwOnCanceled = throwOnCanceled
    }
}
