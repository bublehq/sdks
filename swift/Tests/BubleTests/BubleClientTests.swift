import Buble
import XCTest

final class BubleClientTests: XCTestCase {
    func testSendsAuthorizationHeader() async throws {
        let transport = try TestHTTPTransport(responses: [
            .json(["data": []])
        ])
        let client = try makeClient(transport: transport)

        _ = try await client.mediaModels.list()

        let requests = await transport.recordedRequests()
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer sk_test")
        XCTAssertEqual(request.url?.absoluteString, "https://unit.test/api/v1/media_models")
    }

    func testUsesDefaultBaseURLWhenOmitted() async throws {
        let transport = try TestHTTPTransport(responses: [
            .json(["data": []])
        ])
        let client = try BubleClient(options: BubleClientOptions(apiKey: "sk_test", transport: transport))

        _ = try await client.mediaModels.list()

        let requests = await transport.recordedRequests()
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://buble.ai/api/v1/media_models")
    }

    func testRejectsMissingAPIKey() {
        XCTAssertThrowsError(try BubleClient(options: BubleClientOptions(apiKey: ""))) { error in
            XCTAssertEqual(error as? BubleError, .missingAPIKey)
        }
    }
}
