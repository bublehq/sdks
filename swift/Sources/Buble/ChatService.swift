public typealias ChatRequest = JSONValue
public typealias ChatResponse = JSONValue

/// Chat model methods for OpenAI, Anthropic, and Gemini-compatible APIs.
public struct ChatService: Sendable {
    let http: BubleHTTPClient

    public var models: ChatModelsService {
        ChatModelsService(http: http)
    }

    public var completions: ChatCompletionsService {
        ChatCompletionsService(http: http)
    }

    public var messages: MessagesService {
        MessagesService(http: http)
    }

    public var gemini: GeminiService {
        GeminiService(http: http)
    }
}

public struct ChatModelsService: Sendable {
    let http: BubleHTTPClient

    public func list() async throws -> ChatModelList {
        try await http.request("GET", "/api/v1/models")
    }
}

public struct ChatCompletionsService: Sendable {
    let http: BubleHTTPClient

    public func create(_ body: ChatRequest) async throws -> ChatResponse {
        try await http.requestValue("POST", "/api/v1/chat/completions", body: body.settingStream(false))
    }

    public func stream(_ body: ChatRequest) async throws -> AsyncThrowingStream<ServerSentEvent, Error> {
        try await http.stream("POST", "/api/v1/chat/completions", body: body.settingStream(true))
    }

    public func streamText(_ body: ChatRequest) async throws -> AsyncThrowingStream<String, Error> {
        let events = try await stream(body)
        return StreamText.text(from: events, protocol: .openAI)
    }
}

public struct MessagesService: Sendable {
    let http: BubleHTTPClient

    public func create(_ body: ChatRequest) async throws -> ChatResponse {
        try await http.requestValue("POST", "/api/v1/messages", body: body.settingStream(false))
    }

    public func stream(_ body: ChatRequest) async throws -> AsyncThrowingStream<ServerSentEvent, Error> {
        try await http.stream("POST", "/api/v1/messages", body: body.settingStream(true))
    }

    public func streamText(_ body: ChatRequest) async throws -> AsyncThrowingStream<String, Error> {
        let events = try await stream(body)
        return StreamText.text(from: events, protocol: .anthropic)
    }
}

public struct GeminiService: Sendable {
    let http: BubleHTTPClient

    public func generateContent(_ model: String, body: ChatRequest) async throws -> ChatResponse {
        try await http.requestValue(
            "POST",
            "/api/v1beta/models/\(URLCoding.encodeModelPath(model)):generateContent",
            body: body
        )
    }

    public func streamGenerateContent(_ model: String, body: ChatRequest) async throws -> AsyncThrowingStream<ServerSentEvent, Error> {
        try await http.stream(
            "POST",
            "/api/v1beta/models/\(URLCoding.encodeModelPath(model)):streamGenerateContent",
            body: body
        )
    }

    public func streamText(_ model: String, body: ChatRequest) async throws -> AsyncThrowingStream<String, Error> {
        let events = try await streamGenerateContent(model, body: body)
        return StreamText.text(from: events, protocol: .gemini)
    }
}

private extension JSONValue {
    func settingStream(_ enabled: Bool) -> JSONValue {
        guard case .object(var object) = self else {
            return .object(["stream": .bool(enabled)])
        }
        object["stream"] = .bool(enabled)
        return .object(object)
    }
}
