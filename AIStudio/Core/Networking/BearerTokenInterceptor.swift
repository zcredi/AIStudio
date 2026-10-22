import Foundation

struct BearerTokenInterceptor: RequestInterceptor {
    let token: String

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
