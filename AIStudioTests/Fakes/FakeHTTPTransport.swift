import Foundation
@testable import AIStudio

actor FakeHTTPTransport: HTTPTransport {
    // MARK: - Types

    enum Outcome: Sendable {
        case response(statusCode: Int, body: Data)
        case failure(URLError)
    }

    // MARK: - Properties

    private(set) var receivedRequests: [URLRequest] = []

    private let outcome: Outcome

    // MARK: - Init

    init(outcome: Outcome) {
        self.outcome = outcome
    }

    init(statusCode: Int, json: String) {
        self.init(outcome: .response(statusCode: statusCode, body: Data(json.utf8)))
    }

    // MARK: - HTTPTransport

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        receivedRequests.append(request)
        switch outcome {
        case .response(let statusCode, let body):
            guard
                let url = request.url,
                let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
            else {
                throw URLError(.badURL)
            }
            return (body, response)
        case .failure(let error):
            throw error
        }
    }
}
