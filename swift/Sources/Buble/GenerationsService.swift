/// Direct media generation methods.
public struct GenerationsService: Sendable {
    let http: BubleHTTPClient

    /// Creates an asynchronous image, video, or audio generation task.
    public func create(_ request: CreateGenerationRequest) async throws -> Envelope<GenerationTask> {
        try await http.request("POST", "/api/v1/generations", body: request.body())
    }

    /// Retrieves a media generation task.
    public func retrieve(_ id: String) async throws -> Envelope<GenerationTask> {
        try await http.request("GET", "/api/v1/generations/\(URLCoding.encodePathSegment(id))")
    }

    /// Polls a media generation task until it reaches a terminal status.
    public func wait(_ id: String, options: WaitOptions = WaitOptions()) async throws -> Envelope<GenerationTask> {
        let deadline = Date().addingTimeInterval(options.timeout)
        while true {
            let envelope = try await retrieve(id)
            let task = envelope.data
            if task.status.isTerminal {
                if task.status == .failed, options.throwOnFailed {
                    throw BubleError.generationFailed(task: task)
                }
                if task.status == .canceled, options.throwOnCanceled {
                    throw BubleError.generationCanceled(task: task)
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
