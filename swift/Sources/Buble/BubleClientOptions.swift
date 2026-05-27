/// Configuration used to create a `BubleClient`.
public struct BubleClientOptions: Sendable {
    public static let defaultBaseURL = URL(string: "https://buble.ai")!

    public var apiKey: String?
    public var baseURL: URL?
    public var timeout: TimeInterval
    public var headers: [String: String]
    public var transport: HTTPTransport?

    public init(
        apiKey: String? = nil,
        baseURL: URL? = nil,
        timeout: TimeInterval = 60,
        headers: [String: String] = [:],
        transport: HTTPTransport? = nil
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.timeout = timeout
        self.headers = headers
        self.transport = transport
    }
}
