/// HTTP response returned by an injected transport.
public struct HTTPResponse: Sendable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data

    public init(statusCode: Int, headers: [String: String] = [:], body: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

/// Streaming HTTP response returned by an injected transport.
public struct HTTPStreamResponse {
    public let statusCode: Int
    public let headers: [String: String]
    public let bytes: AsyncThrowingStream<Data, Error>

    public init(statusCode: Int, headers: [String: String] = [:], bytes: AsyncThrowingStream<Data, Error>) {
        self.statusCode = statusCode
        self.headers = headers
        self.bytes = bytes
    }
}

/// Transport abstraction used by the SDK and tests.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> HTTPResponse
    func stream(_ request: URLRequest) async throws -> HTTPStreamResponse
}

/// URLSession-backed HTTP transport.
public struct URLSessionHTTPTransport: HTTPTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> HTTPResponse {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BubleError.transport("Buble API returned a non-HTTP response.")
        }
        return HTTPResponse(
            statusCode: httpResponse.statusCode,
            headers: httpResponse.headerFields,
            body: data
        )
    }

    public func stream(_ request: URLRequest) async throws -> HTTPStreamResponse {
        let (bytes, response) = try await session.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BubleError.transport("Buble API returned a non-HTTP response.")
        }

        let stream = AsyncThrowingStream<Data, Error> { continuation in
            Task {
                do {
                    var buffer = Data()
                    for try await byte in bytes {
                        buffer.append(byte)
                        if byte == 10 {
                            continuation.yield(buffer)
                            buffer.removeAll(keepingCapacity: true)
                        }
                    }
                    if !buffer.isEmpty {
                        continuation.yield(buffer)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }

        return HTTPStreamResponse(
            statusCode: httpResponse.statusCode,
            headers: httpResponse.headerFields,
            bytes: stream
        )
    }
}

private extension HTTPURLResponse {
    var headerFields: [String: String] {
        var output: [String: String] = [:]
        for (key, value) in allHeaderFields {
            if let key = key as? String {
                output[key] = "\(value)"
            }
        }
        return output
    }
}
