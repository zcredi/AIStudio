import Foundation

enum SubscriptionError: Error, Equatable, Sendable {
    case paywallUnavailable
    case productUnavailable
    case purchaseFailed
    case restoreFailed
    case nothingToRestore
}

// MARK: - LocalizedError

extension SubscriptionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .paywallUnavailable:
            String(localized: "Subscription plans are unavailable right now. Please try again.")
        case .productUnavailable:
            String(localized: "This plan is unavailable right now. Please choose another one.")
        case .purchaseFailed:
            String(localized: "The purchase couldn't be completed. Please try again.")
        case .restoreFailed:
            String(localized: "Purchases couldn't be restored. Please try again.")
        case .nothingToRestore:
            String(localized: "No active subscription was found for your Apple ID.")
        }
    }
}
