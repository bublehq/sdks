import Buble
import XCTest

final class AppsTests: XCTestCase {
    func testListsAppsWithQuery() async throws {
        let transport = try TestHTTPTransport(responses: [
            .json([
                "data": [
                    [
                        "id": "video-background-remover",
                        "input_parameters": [
                            ["name": "source_video", "type": "array"]
                        ]
                    ]
                ]
            ])
        ])
        let client = try makeClient(transport: transport)

        let apps = try await client.apps.list(options: ListAppsOptions(limit: 20))

        XCTAssertEqual(apps.data.first?.id, "video-background-remover")
        let requests = await transport.recordedRequests()
        XCTAssertEqual(requests.first?.url?.query, "limit=20")
    }

    func testCreatesAndWaitsForAppGeneration() async throws {
        let transport = try TestHTTPTransport(responses: [
            .json(["data": ["id": "task_1", "status": "pending"]]),
            .json([
                "data": [
                    "id": "task_1",
                    "status": "success",
                    "result": ["videos": [["url": "https://example.com/video.mp4"]]]
                ]
            ])
        ])
        let client = try makeClient(transport: transport)

        let task = try await client.apps.generations.create(
            "video-background-remover",
            body: ["source_video": ["https://example.com/source.mp4"]]
        )
        let result = try await client.apps.generations.wait(
            "video-background-remover",
            task.data.id,
            options: WaitOptions(interval: 0.001, timeout: 1)
        )

        XCTAssertEqual(result.data.result?.videos?.first?.url.absoluteString, "https://example.com/video.mp4")
        let requests = await transport.recordedRequests()
        XCTAssertEqual(requests[0].url?.path, "/api/v1/apps/video-background-remover/generations")
        XCTAssertEqual(requests[1].url?.path, "/api/v1/apps/video-background-remover/generations/task_1")
    }
}
