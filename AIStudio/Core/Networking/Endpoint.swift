import Foundation

/// Один вызов API: что отправить и в какой тип декодируется ответ.
struct Endpoint<Response: Decodable & Sendable>: Sendable {
    // MARK: - Properties

    let method: HTTPMethod
    /// Путь относительно базового пути сервера, например `/dola/chats`.
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
