/// Error type returned by the Buble Swift SDK.
public enum BubleError: Error, Equatable, Sendable {
    case missingAPIKey
    case invalidConfiguration(String)
    case invalidURL(String)
    case api(APIError)
    case decoding(String)
    case transport(String)
    case timeout(TimeInterval)
    case unsupportedGenerationField(field: String)
    case generationFailed(task: GenerationTask)
    case generationCanceled(task: GenerationTask)
    case appGenerationFailed(task: AppGenerationTask)
    case appGenerationCanceled(task: AppGenerationTask)
    case stream(String)
}

/// Non-2xx response returned by the Buble API.
public struct APIError: Error, Codable, Equatable, Sendable {
    public let statusCode: Int
    public let code: String?
    public let message: String
    public let details: JSONValue?
    public let responseBody: String

    public init(statusCode: Int, code: String?, message: String, details: JSONValue?, responseBody: String) {
        self.statusCode = statusCode
        self.code = code
        self.message = message
        self.details = details
        self.responseBody = responseBody
    }
}
