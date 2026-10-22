import XCTest
@testable import AIStudio

final class PixVerseVideoRepositoryTests: XCTestCase {
    private let server = APIServer(host: "api.example.com", basePath: "/pixverse")

    // MARK: - Templates

    func test_templates_mapsActiveTemplatesWithPreview() async throws {
        // Дано
        let transport = try FakeHTTPTransport(outcome: .response(statusCode: 200, body: fixture("pixverse-templates")))
        let repository = makeRepository(transport: transport)

        // Когда
        let templates = try await repository.templates()

        // Тогда
        XCTAssertEqual(templates.map(\.id), [374743997109542, 383217104128057])
        let snowflakes = try XCTUnwrap(templates.first)
        XCTAssertEqual(snowflakes.name, "Dense Snowflakes")
        XCTAssertEqual(snowflakes.category, "📈 Trending")
        XCTAssertEqual(snowflakes.largePreviewURL, URL(string: "https://media.example.com/large.mp4"))
    }

    func test_templates_sortsKnownQualitiesAndDropsUnknown() async throws {
        let transport = try FakeHTTPTransport(outcome: .response(statusCode: 200, body: fixture("pixverse-templates")))

        let templates = try await makeRepository(transport: transport).templates()

        XCTAssertEqual(templates.first?.qualities, [.p360, .p720, .p1080])
    }

    func test_templates_withoutQualitiesOrLargePreview_fallsBack() async throws {
        let transport = try FakeHTTPTransport(outcome: .response(statusCode: 200, body: fixture("pixverse-templates")))

        let rocky = try await makeRepository(transport: transport).templates().last

        XCTAssertEqual(rocky?.qualities, VideoQuality.allCases)
        XCTAssertEqual(rocky?.largePreviewURL, URL(string: "https://media.example.com/rocky.mp4"))
    }

    func test_templates_requestsCatalogForAppID() async throws {
        let transport = FakeHTTPTransport(statusCode: 200, json: #"{"templates": []}"#)

        _ = try await makeRepository(transport: transport).templates()

        let path = await transport.receivedRequests.last?.url?.path()
        XCTAssertEqual(path, "/pixverse/api/v1/get_templates/com.test.test")
    }

    // MARK: - Generation

    func test_startGeneration_sendsMultipartAndReturnsVideoID() async throws {
        // Дано
        let transport = FakeHTTPTransport(statusCode: 201, json: #"{"video_id": 42, "detail": "Success"}"#)
        let repository = makeRepository(transport: transport)

        // Когда
        let id = try await repository.startGeneration(templateID: 7, image: Data([0xFF, 0xD8]), quality: .p720)

        // Тогда
        XCTAssertEqual(id, 42)
        let lastRequest = await transport.receivedRequests.last
        let request = try XCTUnwrap(lastRequest)
        XCTAssertEqual(request.url?.path(), "/pixverse/api/v1/template2video")
        let body = String(decoding: request.httpBody ?? Data(), as: UTF8.self)
        XCTAssertTrue(body.contains("name=\"template_id\"\r\n\r\n7\r\n"))
        XCTAssertTrue(body.contains("name=\"quality\"\r\n\r\n720p\r\n"))
        XCTAssertTrue(body.contains("name=\"image\"; filename=\"image.jpg\""))
    }

    func test_status_whenSucceeded_returnsVideoURL() async throws {
        let transport = FakeHTTPTransport(statusCode: 200, json: #"{"status": "success", "video_url": "https://cdn.example.com/v.mp4"}"#)

        let status = try await makeRepository(transport: transport).status(ofGeneration: 42)

        XCTAssertEqual(status, .succeeded(videoURL: try XCTUnwrap(URL(string: "https://cdn.example.com/v.mp4"))))
        let query = await transport.receivedRequests.last?.url?.query()
        XCTAssertEqual(query, "id=42")
    }

    func test_status_whenSucceededWithoutURL_throwsInvalidResponse() async {
        let transport = FakeHTTPTransport(statusCode: 200, json: #"{"status": "success", "video_url": null}"#)

        do {
            _ = try await makeRepository(transport: transport).status(ofGeneration: 42)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .invalidResponse)
        }
    }

    func test_status_mapsErrorAndInFlightStates() async throws {
        let failed = FakeHTTPTransport(statusCode: 200, json: #"{"status": "error"}"#)
        let queued = FakeHTTPTransport(statusCode: 200, json: #"{"status": "queued"}"#)

        let failedStatus = try await makeRepository(transport: failed).status(ofGeneration: 1)
        let queuedStatus = try await makeRepository(transport: queued).status(ofGeneration: 1)

        XCTAssertEqual(failedStatus, .failed)
        XCTAssertEqual(queuedStatus, .generating)
    }

    // MARK: - Private

    private func makeRepository(transport: FakeHTTPTransport) -> PixVerseVideoRepository {
        PixVerseVideoRepository(
            client: URLSessionAPIClient(server: server, transport: transport),
            appID: "com.test.test"
        )
    }

    private func fixture(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}
