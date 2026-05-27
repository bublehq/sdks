/// Streaming protocol used to extract text from SSE payloads.
public enum StreamProtocol: Sendable {
    case openAI
    case anthropic
    case gemini
}

/// Parsed server-sent event.
public struct ServerSentEvent: Equatable, Sendable {
    public let event: String?
    public let data: String
    public let json: JSONValue?
}

enum ServerSentEventParser {
    static func events(from bytes: AsyncThrowingStream<Data, Error>) -> AsyncThrowingStream<ServerSentEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var parser = Parser()
                do {
                    for try await chunk in bytes {
                        let text = String(decoding: chunk, as: UTF8.self)
                        for event in try parser.push(text) {
                            if event.data == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            continuation.yield(event)
                        }
                    }
                    for event in try parser.finish() {
                        if event.data == "[DONE]" {
                            continuation.finish()
                            return
                        }
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    struct Parser {
        var pending = ""
        var event: String?
        var dataLines: [String] = []

        mutating func push(_ chunk: String) throws -> [ServerSentEvent] {
            pending += chunk
            var output: [ServerSentEvent] = []
            while let newline = pending.firstIndex(of: "\n") {
                var line = String(pending[..<newline])
                pending.removeSubrange(...newline)
                if line.hasSuffix("\r") {
                    line.removeLast()
                }
                if let event = try pushLine(line) {
                    output.append(event)
                }
            }
            return output
        }

        mutating func finish() throws -> [ServerSentEvent] {
            var output: [ServerSentEvent] = []
            if !pending.isEmpty {
                let line = pending
                pending = ""
                if let event = try pushLine(line.trimmingCharacters(in: CharacterSet(charactersIn: "\r"))) {
                    output.append(event)
                }
            }
            if let event = try flush() {
                output.append(event)
            }
            return output
        }

        mutating func pushLine(_ line: String) throws -> ServerSentEvent? {
            if line.isEmpty {
                return try flush()
            }
            if line.hasPrefix(":") {
                return nil
            }
            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let field = String(parts[0])
            let value = parts.count > 1 ? String(parts[1]).trimmingPrefix(" ") : ""
            switch field {
            case "event":
                event = value
            case "data":
                dataLines.append(value)
            default:
                break
            }
            return nil
        }

        mutating func flush() throws -> ServerSentEvent? {
            guard event != nil || !dataLines.isEmpty else {
                return nil
            }
            let data = dataLines.joined(separator: "\n")
            dataLines = []
            let currentEvent = event
            event = nil

            let json: JSONValue?
            if data.isEmpty || data == "[DONE]" {
                json = nil
            } else if let decoded = try? JSONDecoder().decode(JSONValue.self, from: Data(data.utf8)) {
                json = decoded
            } else {
                json = nil
            }

            return ServerSentEvent(event: currentEvent, data: data, json: json)
        }
    }
}

private extension String {
    func trimmingPrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
}
