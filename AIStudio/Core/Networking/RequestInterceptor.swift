import Foundation

/// Adjusts every outgoing request, e.g. adds credentials or client identity.
protocol RequestInterceptor: Sendable {
    func adapt(_ request: URLRequest) async throws -> URLRequest
}
