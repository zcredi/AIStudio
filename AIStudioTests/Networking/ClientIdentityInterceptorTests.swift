import XCTest
@testable import AIStudio

final class ClientIdentityInterceptorTests: XCTestCase {
    private let interceptor = ClientIdentityInterceptor(appID: "com.test.test") { "user-1" }

    func test_adapt_withoutQuery_addsUserAndAppID() async throws {
        let request = try makeRequest("https://api.example.com/dola/chats")

        let adapted = try await interceptor.adapt(request)

        XCTAssertEqual(adapted.url?.query, "user_id=user-1&app_id=com.test.test")
    }

    func test_adapt_withEncodedQuery_keepsItAndAppendsIdentity() async throws {
        let request = try makeRequest("https://api.example.com/dola/search?q=1%2B1")

        let adapted = try await interceptor.adapt(request)

        XCTAssertEqual(adapted.url?.query, "q=1%2B1&user_id=user-1&app_id=com.test.test")
    }

    func test_adapt_keepsMethodHeadersAndBody() async throws {
        // Дано
        var request = try makeRequest("https://api.example.com/dola/chats")
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Когда
        let adapted = try await interceptor.adapt(request)

        // Тогда
        XCTAssertEqual(adapted.httpMethod, "POST")
        XCTAssertEqual(adapted.httpBody, Data("{}".utf8))
        XCTAssertEqual(adapted.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    // MARK: - Private

    private func makeRequest(_ string: String) throws -> URLRequest {
        URLRequest(url: try XCTUnwrap(URL(string: string)))
    }
}
