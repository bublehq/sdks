/// Query parameters for listing apps.
public struct ListAppsOptions: Sendable {
    public var page: Int?
    public var limit: Int?

    public init(page: Int? = nil, limit: Int? = nil) {
        self.page = page
        self.limit = limit
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let page { items.append(URLQueryItem(name: "page", value: "\(page)")) }
        if let limit { items.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        return items
    }
}

/// Preconfigured app workflow methods.
public struct AppsService: Sendable {
    let http: BubleHTTPClient

    /// App generation methods.
    public var generations: AppGenerationsService {
        AppGenerationsService(http: http)
    }

    /// Lists callable app workflows.
    public func list(options: ListAppsOptions = ListAppsOptions()) async throws -> Envelope<[PublicApp]> {
        try await http.request("GET", "/api/v1/apps", query: options.queryItems)
    }

    /// Retrieves one callable app workflow.
    public func retrieve(_ appID: String) async throws -> Envelope<PublicApp> {
        try await http.request("GET", "/api/v1/apps/\(URLCoding.encodePathSegment(appID))")
    }
}

/// App generation task methods.
public struct AppGenerationsService: Sendable {
    let http: BubleHTTPClient

    /// Creates an asynchronous generation task from an app.
    public func create(_ appID: String, body: [String: JSONValue]) async throws -> Envelope<AppGenerationTask> {
        try await http.request(
            "POST",
            "/api/v1/apps/\(URLCoding.encodePathSegment(appID))/generations",
            body: .object(body)
        )
    }

    /// Retrieves an app generation task.
    public func retrieve(_ appID: String, _ generationID: String) async throws -> Envelope<AppGenerationTask> {
        try await http.request(
            "GET",
            "/api/v1/apps/\(URLCoding.encodePathSegment(appID))/generations/\(URLCoding.encodePathSegment(generationID))"
        )
    }

    /// Polls an app generation task until it reaches a terminal status.
    public func wait(_ appID: String, _ generationID: String, options: WaitOptions = WaitOptions()) async throws -> Envelope<AppGenerationTask> {
        let deadline = Date().addingTimeInterval(options.timeout)
        while true {
            let envelope = try await retrieve(appID, generationID)
            let task = envelope.data
            if task.status.isTerminal {
                if task.status == .failed, options.throwOnFailed {
                    throw BubleError.appGenerationFailed(task: task)
                }
                if task.status == .canceled, options.throwOnCanceled {
                    throw BubleError.appGenerationCanceled(task: task)
                }
                return envelope
            }

            if Date() >= deadline {
                throw BubleError.timeout(options.timeout)
            }
            try await Task.sleep(nanoseconds: UInt64(options.interval * 1_000_000_000))
        }
    }
}
