import Foundation

/// Дорабатывает каждый исходящий запрос, например добавляет авторизацию или данные клиента.
protocol RequestInterceptor: Sendable {
    func adapt(_ request: URLRequest) async throws -> URLRequest
}
