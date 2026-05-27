enum StreamText {
    static func text(from events: AsyncThrowingStream<ServerSentEvent, Error>, protocol streamProtocol: StreamProtocol) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await event in events {
                        let text = extractText(from: event, protocol: streamProtocol)
                        if !text.isEmpty {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    static func extractText(from event: ServerSentEvent, protocol streamProtocol: StreamProtocol) -> String {
        guard let json = event.json else {
            return ""
        }
        switch streamProtocol {
        case .openAI:
            return json.value(at: ["choices", "0", "delta", "content"])?.stringValue ?? ""
        case .anthropic:
            guard event.event == "content_block_delta" else {
                return ""
            }
            return json.value(at: ["delta", "text"])?.stringValue ?? ""
        case .gemini:
            guard let parts = json.value(at: ["candidates", "0", "content", "parts"])?.arrayValue else {
                return ""
            }
            return parts.compactMap { $0.value(at: ["text"])?.stringValue }.joined()
        }
    }
}
