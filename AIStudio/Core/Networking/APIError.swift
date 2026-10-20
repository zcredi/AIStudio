import Foundation

/// Errors thrown by `APIClient`. A cancelled request throws `CancellationError` instead.
enum APIError: Error, Equatable, Sendable {
    /// The request could not be built: invalid URL or a body that failed to encode.
    case invalidRequest
    case offline
    case timeout
    case transport(URLError.Code)
    case unauthorized
    /// HTTP 402: the account has run out of credits for the operation.
    case insufficientCredits
    case notFound
    case validation(message: String?)
    case http(statusCode: Int, message: String?)
    case invalidResponse
    case decoding
}

// MARK: - Mapping

extension APIError {
    init(statusCode: Int, message: String?) {
        switch statusCode {
        case 401, 403:
            self = .unauthorized
        case 402:
            self = .insufficientCredits
        case 404:
            self = .notFound
        case 422:
            self = .validation(message: message)
        default:
            self = .http(statusCode: statusCode, message: message)
        }
    }

    init(_ error: URLError) {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            self = .offline
        case .timedOut:
            self = .timeout
        default:
            self = .transport(error.code)
        }
    }
}
