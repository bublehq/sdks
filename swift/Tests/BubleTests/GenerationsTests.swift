import Buble
import XCTest

final class GenerationsTests: XCTestCase {
    func testCreatesFlatGenerationBody() async throws {
        let transport = try TestHTTPTransport(responses: [
            .json(["data": ["id": "task_1", "status": "pending"]])
        ])
        let client = try makeClient(transport: transport)

        let task = try await client.generations.create(
            try CreateGenerationRequest(model: "google/nano-banana")
                .mode("text_to_image")
                .prompt("A product image")
                .param("aspect_ratio", "1:1")
                .param("output_format", "png")
        )

        XCTAssertEqual(task.data.id, "task_1")
        let requests = await transport.recordedRequests()
        let body = try requestBody(XCTUnwrap(requests.first))
        XCTAssertEqual(body.value(at: ["model"])?.stringValue, "google/nano-banana")
        XCTAssertEqual(body.value(at: ["mode"])?.stringValue, "text_to_image")
        XCTAssertEqual(body.value(at: ["aspect_ratio"])?.stringValue, "1:1")
        XCTAssertNil(body.value(at: ["options"]))
    }

    func testRejectsInternalGenerationFields() {
        XCTAssertThrowsError(try CreateGenerationRequest(model: "google/nano-banana").param("options", ["duration": "5s"])) { error in
            XCTAssertEqual(error as? BubleError, .unsupportedGenerationField(field: "options"))
        }
    }

    func testWaitsUntilSuccess() async throws {
        let transport = try TestHTTPTransport(responses: [
            .json([
                "data": [
                    "id": "task_1",
                    "status": "success",
                    "result": [
                        "images": [
                            ["url": "https://example.com/image.png"]
                        ]
                    ]
                ]
            ])
        ])
        let client = try makeClient(transport: transport)

        let result = try await client.generations.wait("task_1", options: WaitOptions(interval: 0.001, timeout: 1))

        XCTAssertEqual(result.data.result?.images?.first?.url.absoluteString, "https://example.com/image.png")
        let requests = await transport.recordedRequests()
        XCTAssertEqual(requests.first?.url?.path, "/api/v1/generations/task_1")
    }

    func testRaisesOnFailedGeneration() async throws {
        let transport = try TestHTTPTransport(responses: [
            .json([
                "data": [
                    "id": "task_1",
                    "status": "failed",
                    "error": ["message": "provider failed"]
                ]
            ])
        ])
        let client = try makeClient(transport: transport)

        do {
            _ = try await client.generations.wait("task_1", options: WaitOptions(interval: 0.001, timeout: 1))
            XCTFail("Expected failed generation")
        } catch BubleError.generationFailed(let task) {
            XCTAssertEqual(task.error?.message, "provider failed")
        }
    }
}
