import Foundation

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .offline:
            String(localized: "No internet connection. Check your network and try again.")
        case .timeout:
            String(localized: "The server is taking too long to respond. Please try again.")
        case .insufficientCredits:
            String(localized: "Not enough credits for this operation.")
        case .unauthorized:
            String(localized: "Access to the service was denied.")
        case .invalidRequest, .transport, .notFound, .validation, .http, .invalidResponse, .decoding:
            String(localized: "Something went wrong. Please try again.")
        }
    }
}
