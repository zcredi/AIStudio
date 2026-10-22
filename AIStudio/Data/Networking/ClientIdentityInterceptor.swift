import Foundation

/// Добавляет query-параметры `user_id` и `app_id`, которых требуют API Dola и PixVerse.
struct ClientIdentityInterceptor: RequestInterceptor {
    // MARK: - Properties

    private let appID: String
    private let currentUserID: @Sendable () async -> String

    // MARK: - Init

    /// `userID` запрашивается для каждого запроса: SDK подписок может сменить ID во время работы.
    init(appID: String, userID: @escaping @Sendable () async -> String) {
        self.appID = appID
        self.currentUserID = userID
    }

    // MARK: - RequestInterceptor

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard
            let url = request.url,
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            throw APIError.invalidRequest
        }

        let userID = await currentUserID()
        let identity = FormURLEncoder.encodedString([
            URLQueryItem(name: "user_id", value: userID),
            URLQueryItem(name: "app_id", value: appID),
        ])
        // Добавление к уже закодированному query сохраняет экранирование существующих параметров.
        components.percentEncodedQuery = [components.percentEncodedQuery, identity]
            .compactMap { $0 }
            .joined(separator: "&")

        guard let identifiedURL = components.url else { throw APIError.invalidRequest }
        var request = request
        request.url = identifiedURL
        return request
    }
}
