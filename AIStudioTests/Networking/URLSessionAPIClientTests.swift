import XCTest
@testable import AIStudio

final class URLSessionAPIClientTests: XCTestCase {
    private struct Greeting: Decodable, Sendable, Equatable {
        let text: String
    }

    private struct Message: Encodable, Sendable {
        let message: String
    }

    private struct HeaderInterceptor: RequestInterceptor {
        func adapt(_ request: URLRequest) async throws -> URLRequest {
            var request = request
            request.setValue("Bearer test", forHTTPHeaderField: "Authorization")
            return request
        }
    }

    private let server = APIServer(host: "api.example.com", basePath: "/dola")

    // MARK: - Request

    func test_send_buildsURLFromServerPathAndQuery() async throws {
        // Given
        let transport = FakeHTTPTransport(statusCode: 200, json: #"{"text": "hi"}"#)
        let client = URLSessionAPIClient(server: server, transport: transport)
        let endpoint = Endpoint<Greeting>.get("/chats", queryItems: [URLQueryItem(name: "limit", value: "20")])

        // When
        _ = try await client.send(endpoint)

        // Then
        let request = try await lastRequest(of: transport)
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/dola/chats?limit=20")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func test_send_withPlusInQuery_percentEncodesIt() async throws {
        let transport = FakeHTTPTransport(statusCode: 200, json: #"{"text": "hi"}"#)
        let client = URLSessionAPIClient(server: server, transport: transport)

        _ = try await client.send(Endpoint<Greeting>.get("/search", queryItems: [URLQueryItem(name: "q", value: "1+1")]))

        let request = try await lastRequest(of: transport)
        XCTAssertEqual(request.url?.query, "q=1%2B1")
    }

    func test_send_withJSONBody_setsBodyAndContentType() async throws {
        let transport = FakeHTTPTransport(statusCode: 200, json: #"{"text": "hi"}"#)
        let client = URLSessionAPIClient(server: server, transport: transport)

        _ = try await client.send(Endpoint<Greeting>.post("/messages", body: .json(Message(message: "Hello"))))

        let request = try await lastRequest(of: transport)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.httpBody, Data(#"{"message":"Hello"}"#.utf8))
    }

    func test_send_withInterceptor_appliesItToRequest() async throws {
        let transport = FakeHTTPTransport(statusCode: 200, json: #"{"text": "hi"}"#)
        let client = URLSessionAPIClient(server: server, transport: transport, interceptors: [HeaderInterceptor()])

        _ = try await client.send(Endpoint<Greeting>.get("/chats"))

        let request = try await lastRequest(of: transport)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test")
    }

    func test_send_withCustomTimeout_setsItOnRequest() async throws {
        let transport = FakeHTTPTransport(statusCode: 200, json: #"{"text": "hi"}"#)
        let client = URLSessionAPIClient(server: server, transport: transport)

        _ = try await client.send(Endpoint<Greeting>.get("/status", timeout: RequestTimeout.generation))

        let request = try await lastRequest(of: transport)
        XCTAssertEqual(request.timeoutInterval, RequestTimeout.generation)
    }

    // MARK: - Response

    func test_send_withSuccess_decodesResponse() async throws {
        let transport = FakeHTTPTransport(statusCode: 200, json: #"{"text": "hi"}"#)
        let client = URLSessionAPIClient(server: server, transport: transport)

        let greeting = try await client.send(Endpoint<Greeting>.get("/chats"))

        XCTAssertEqual(greeting, Greeting(text: "hi"))
    }

    func test_send_withPaymentRequired_throwsInsufficientCredits() async {
        let transport = FakeHTTPTransport(statusCode: 402, json: #"{"detail": "Insufficient balance"}"#)
        let client = URLSessionAPIClient(server: server, transport: transport)

        await assertThrows(APIError.insufficientCredits) {
            try await client.send(Endpoint<Greeting>.get("/chats"))
        }
    }

    func test_send_withValidationError_throwsServerMessage() async {
        let json = #"{"detail": [{"loc": ["query", "user_id"], "msg": "Field required", "type": "missing"}]}"#
        let client = URLSessionAPIClient(server: server, transport: FakeHTTPTransport(statusCode: 422, json: json))

        await assertThrows(APIError.validation(message: "Field required")) {
            try await client.send(Endpoint<Greeting>.get("/chats"))
        }
    }

    func test_send_withServerError_throwsHTTPError() async {
        let client = URLSessionAPIClient(server: server, transport: FakeHTTPTransport(statusCode: 502, json: "Bad Gateway"))

        await assertThrows(APIError.http(statusCode: 502, message: nil)) {
            try await client.send(Endpoint<Greeting>.get("/chats"))
        }
    }

    func test_send_withUnexpectedBody_throwsDecoding() async {
        let client = URLSessionAPIClient(server: server, transport: FakeHTTPTransport(statusCode: 200, json: "[]"))

        await assertThrows(APIError.decoding) {
            try await client.send(Endpoint<Greeting>.get("/chats"))
        }
    }

    func test_send_withoutConnection_throwsOffline() async {
        let transport = FakeHTTPTransport(outcome: .failure(URLError(.notConnectedToInternet)))
        let client = URLSessionAPIClient(server: server, transport: transport)

        await assertThrows(APIError.offline) {
            try await client.send(Endpoint<Greeting>.get("/chats"))
        }
    }

    func test_send_whenCancelled_throwsCancellationError() async {
        let transport = FakeHTTPTransport(outcome: .failure(URLError(.cancelled)))
        let client = URLSessionAPIClient(server: server, transport: transport)

        do {
            _ = try await client.send(Endpoint<Greeting>.get("/chats"))
            XCTFail("Expected CancellationError")
        } catch {
            XCTAssertTrue(error is CancellationError, "Unexpected error: \(error)")
        }
    }

    // MARK: - Private

    private func lastRequest(of transport: FakeHTTPTransport) async throws -> URLRequest {
        let requests = await transport.receivedRequests
        return try XCTUnwrap(requests.last)
    }

    private func assertThrows<Result>(
        _ expected: APIError,
        _ operation: () async throws -> Result,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? APIError, expected, file: file, line: line)
        }
    }
}
