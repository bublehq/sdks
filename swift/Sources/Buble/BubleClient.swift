/// Server-side client for the Buble public API.
public final class BubleClient: @unchecked Sendable {
    public let mediaModels: MediaModelsService
    public let files: FilesService
    public let generations: GenerationsService
    public let apps: AppsService
    public let chat: ChatService

    let http: BubleHTTPClient

    public init(options: BubleClientOptions) throws {
        let apiKey = options.apiKey ?? ProcessInfo.processInfo.environment["BUBLE_API_KEY"]
        guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BubleError.missingAPIKey
        }

        let baseURL: URL
        if let configuredBaseURL = options.baseURL {
            baseURL = configuredBaseURL
        } else if let value = ProcessInfo.processInfo.environment["BUBLE_BASE_URL"], !value.isEmpty {
            guard let url = URL(string: value) else {
                throw BubleError.invalidURL(value)
            }
            baseURL = url
        } else {
            baseURL = BubleClientOptions.defaultBaseURL
        }

        let http = BubleHTTPClient(
            apiKey: apiKey,
            baseURL: baseURL,
            timeout: options.timeout,
            headers: options.headers,
            transport: options.transport ?? URLSessionHTTPTransport()
        )

        self.http = http
        self.mediaModels = MediaModelsService(http: http)
        self.files = FilesService(http: http)
        self.generations = GenerationsService(http: http)
        self.apps = AppsService(http: http)
        self.chat = ChatService(http: http)
    }

    public convenience init(apiKey: String) throws {
        try self.init(options: BubleClientOptions(apiKey: apiKey))
    }

    /// Creates a client from `BUBLE_API_KEY` and optional `BUBLE_BASE_URL`.
    public static func fromEnvironment() throws -> BubleClient {
        try BubleClient(options: BubleClientOptions())
    }
}

/// Namespace marker for the Buble Swift SDK.
public enum Buble {}
