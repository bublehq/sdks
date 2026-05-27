final class BubleHTTPClient: @unchecked Sendable {
    private let apiKey: String
    private let baseURL: URL
    private let timeout: TimeInterval
    private let headers: [String: String]
    private let transport: HTTPTransport
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(apiKey: String, baseURL: URL, timeout: TimeInterval, headers: [String: String], transport: HTTPTransport) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.timeout = timeout
        self.headers = headers
        self.transport = transport
    }

    func request<T: Decodable>(
        _ method: String,
        _ path: String,
        query: [URLQueryItem] = [],
        body: JSONValue? = nil,
        responseType: T.Type = T.self
    ) async throws -> T {
        let request = try makeRequest(method, path, query: query, body: body, accept: "application/json")
        do {
            let response = try await transport.send(request)
            try throwIfAPIError(response)
            do {
                return try decoder.decode(T.self, from: response.body)
            } catch {
                throw BubleError.decoding(error.localizedDescription)
            }
        } catch let error as BubleError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw BubleError.timeout(timeout)
        } catch {
            throw BubleError.transport(error.localizedDescription)
        }
    }

    func requestValue(_ method: String, _ path: String, body: JSONValue? = nil) async throws -> JSONValue {
        try await request(method, path, body: body, responseType: JSONValue.self)
    }

    func requestMultipart<T: Decodable>(
        _ path: String,
        fields: [String: String],
        file: FileUpload,
        responseType: T.Type = T.self
    ) async throws -> T {
        let multipart = try file.multipartBody(fields: fields)
        var request = try makeRequest("POST", path, body: nil, accept: "application/json")
        request.setValue(multipart.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = multipart.body

        do {
            let response = try await transport.send(request)
            try throwIfAPIError(response)
            do {
                return try decoder.decode(T.self, from: response.body)
            } catch {
                throw BubleError.decoding(error.localizedDescription)
            }
        } catch let error as BubleError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw BubleError.timeout(timeout)
        } catch {
            throw BubleError.transport(error.localizedDescription)
        }
    }

    func stream(_ method: String, _ path: String, body: JSONValue? = nil) async throws -> AsyncThrowingStream<ServerSentEvent, Error> {
        let request = try makeRequest(method, path, body: body, accept: "text/event-stream")
        do {
            let response = try await transport.stream(request)
            if response.statusCode < 200 || response.statusCode >= 300 {
                let buffered = try await collect(response.bytes)
                throw makeAPIError(statusCode: response.statusCode, body: buffered)
            }
            return ServerSentEventParser.events(from: response.bytes)
        } catch let error as BubleError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw BubleError.timeout(timeout)
        } catch {
            throw BubleError.transport(error.localizedDescription)
        }
    }

    private func makeRequest(
        _ method: String,
        _ path: String,
        query: [URLQueryItem] = [],
        body: JSONValue? = nil,
        accept: String
    ) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw BubleError.invalidURL(baseURL.absoluteString)
        }
        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let requestPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + [basePath, requestPath].filter { !$0.isEmpty }.joined(separator: "/")
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else {
            throw BubleError.invalidURL("\(baseURL.absoluteString)\(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(accept, forHTTPHeaderField: "Accept")
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }
        return request
    }

    private func throwIfAPIError(_ response: HTTPResponse) throws {
        guard response.statusCode < 200 || response.statusCode >= 300 else {
            return
        }
        throw makeAPIError(statusCode: response.statusCode, body: response.body)
    }

    private func makeAPIError(statusCode: Int, body: Data) -> BubleError {
        let responseBody = String(data: body, encoding: .utf8) ?? ""
        var message = responseBody.isEmpty ? "Buble API request failed with status \(statusCode)." : responseBody
        var code: String?
        var details: JSONValue?

        if let envelope = try? decoder.decode(APIErrorEnvelope.self, from: body), let error = envelope.error {
            message = error.message ?? message
            code = error.code
            details = error.details
        }

        return .api(APIError(statusCode: statusCode, code: code, message: message, details: details, responseBody: responseBody))
    }

    private func collect(_ stream: AsyncThrowingStream<Data, Error>) async throws -> Data {
        var output = Data()
        for try await chunk in stream {
            output.append(chunk)
        }
        return output
    }
}

private struct APIErrorEnvelope: Decodable {
    let error: Body?

    struct Body: Decodable {
        let code: String?
        let message: String?
        let details: JSONValue?
    }
}
