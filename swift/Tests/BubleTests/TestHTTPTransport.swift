import Buble
import XCTest

actor TestHTTPTransport: HTTPTransport {
    private var responses: [HTTPResponse]
    private var streamResponses: [HTTPStreamResponse]
    private(set) var requests: [URLRequest] = []

    init(responses: [HTTPResponse] = [], streamResponses: [HTTPStreamResponse] = []) {
        self.responses = responses
        self.streamResponses = streamResponses
    }

    func send(_ request: URLRequest) async throws -> HTTPResponse {
        requests.append(request)
        let response = responses.isEmpty ? HTTPResponse(statusCode: 404, body: Data()) : responses.removeFirst()
        return response
    }

    func stream(_ request: URLRequest) async throws -> HTTPStreamResponse {
        requests.append(request)
        let response = streamResponses.isEmpty ? HTTPStreamResponse(statusCode: 404, bytes: .fromChunks([])) : streamResponses.removeFirst()
        return response
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

extension HTTPResponse {
    static func json(_ value: JSONValue, statusCode: Int = 200) throws -> HTTPResponse {
        HTTPResponse(statusCode: statusCode, headers: ["Content-Type": "application/json"], body: try JSONEncoder().encode(value))
    }
}

extension AsyncThrowingStream where Element == Data, Failure == Error {
    static func fromChunks(_ chunks: [String]) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            for chunk in chunks {
                continuation.yield(Data(chunk.utf8))
            }
            continuation.finish()
        }
    }
}

func makeClient(transport: TestHTTPTransport) throws -> BubleClient {
    try BubleClient(
        options: BubleClientOptions(
            apiKey: "sk_test",
            baseURL: URL(string: "https://unit.test")!,
            transport: transport
        )
    )
}

func requestBody(_ request: URLRequest) throws -> JSONValue {
    try JSONDecoder().decode(JSONValue.self, from: XCTUnwrap(request.httpBody))
}
