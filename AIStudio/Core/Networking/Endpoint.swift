import Foundation

/// A single API call: what to send and which type the response decodes into.
struct Endpoint<Response: Decodable & Sendable>: Sendable {
    // MARK: - Properties

    let method: HTTPMethod
    /// Path relative to the server's base path, e.g. `/dola/chats`.
    let path: String
    let queryItems: [URLQueryItem]
    let body: RequestBody?
    let timeout: TimeInterval

    // MARK: - API

    static func get(
        _ path: String,
        queryItems: [URLQueryItem] = [],
        timeout: TimeInterval = RequestTimeout.standard
    ) -> Endpoint {
        Endpoint(method: .get, path: path, queryItems: queryItems, body: nil, timeout: timeout)
    }

    static func post(
        _ path: String,
        body: RequestBody,
        queryItems: [URLQueryItem] = [],
        timeout: TimeInterval = RequestTimeout.standard
    ) -> Endpoint {
        Endpoint(method: .post, path: path, queryItems: queryItems, body: body, timeout: timeout)
    }
}
