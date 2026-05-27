import Buble
import XCTest

final class FilesTests: XCTestCase {
    func testUploadsMultipartFile() async throws {
        let transport = try TestHTTPTransport(responses: [
            .json([
                "data": [
                    "object": "file",
                    "provider": "r2",
                    "url": "https://example.com/source.png",
                    "key": "api/image/source.png",
                    "file_type": "image",
                    "content_type": "image/png",
                    "size": 3,
                    "filename": "source.png"
                ]
            ])
        ])
        let client = try makeClient(transport: transport)

        let uploaded = try await client.files.upload(
            .fromData(Data([1, 2, 3]), filename: "source.png", contentType: "image/png"),
            options: UploadOptions(fileType: "image", model: "google/nano-banana", mode: "image_to_image")
        )

        let requests = await transport.recordedRequests()
        let request = try XCTUnwrap(requests.first)
        let body = String(data: try XCTUnwrap(request.httpBody), encoding: .utf8) ?? ""
        XCTAssertEqual(uploaded.data.url.absoluteString, "https://example.com/source.png")
        XCTAssertTrue(body.contains("name=\"file_type\""))
        XCTAssertTrue(body.contains("image_to_image"))
        XCTAssertTrue(body.contains("filename=\"source.png\""))
    }
}
