import Buble
import XCTest

final class ChatTests: XCTestCase {
    func testCreatesOpenAIChatCompletion() async throws {
        let transport = try TestHTTPTransport(responses: [
            .json(["choices": [["message": ["content": "Hello"]]]])
        ])
        let client = try makeClient(transport: transport)

        let response = try await client.chat.completions.create([
            "model": "openai/gpt-5.4",
            "messages": [
                ["role": "user", "content": "Hi"]
            ]
        ])

        XCTAssertEqual(response.value(at: ["choices", "0", "message", "content"])?.stringValue, "Hello")
        let requests = await transport.recordedRequests()
        let body = try requestBody(XCTUnwrap(requests.first))
        XCTAssertEqual(body.value(at: ["stream"]), .bool(false))
    }

    func testStreamsOpenAIText() async throws {
        let stream = HTTPStreamResponse(
            statusCode: 200,
            headers: ["Content-Type": "text/event-stream"],
            bytes: .fromChunks([
                #"data: {"choices":[{"delta":{"content":"Hel"}}]}"# + "\n\n",
                #"data: {"choices":[{"delta":{"content":"lo"}}]}"# + "\n\n",
                "data: [DONE]\n\n"
            ])
        )
        let transport = TestHTTPTransport(streamResponses: [stream])
        let client = try makeClient(transport: transport)

        let textStream = try await client.chat.completions.streamText([
            "model": "openai/gpt-5.4",
            "messages": [
                ["role": "user", "content": "Hi"]
            ]
        ])

        var output = ""
        for try await text in textStream {
            output += text
        }

        XCTAssertEqual(output, "Hello")
    }

    func testCallsGeminiModelPath() async throws {
        let transport = try TestHTTPTransport(responses: [
            .json(["candidates": []])
        ])
        let client = try makeClient(transport: transport)

        _ = try await client.chat.gemini.generateContent(
            "openai/gpt-5.4",
            body: ["contents": []]
        )

        let requests = await transport.recordedRequests()
        XCTAssertEqual(requests.first?.url?.path, "/api/v1beta/models/openai/gpt-5.4:generateContent")
    }
}
