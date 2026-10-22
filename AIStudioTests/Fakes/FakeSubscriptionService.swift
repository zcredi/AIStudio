import Foundation
@testable import AIStudio

@MainActor
final class FakeSubscriptionService: SubscriptionPurchasing {
    var paywallResult: Result<Paywall, any Error> = .success(Paywall(products: []))
    var purchaseResult: Result<PurchaseOutcome, any Error> = .success(.purchased)
    var restoreError: (any Error)?

    private(set) var purchasedProducts: [PaywallProduct] = []
    private(set) var restoreCallCount = 0

    func loadPaywall() async throws -> Paywall {
        try paywallResult.get()
    }

    func purchase(_ product: PaywallProduct) async throws -> PurchaseOutcome {
        purchasedProducts.append(product)
        return try purchaseResult.get()
    }

    func restorePurchases() async throws {
        restoreCallCount += 1
        if let restoreError {
            throw restoreError
        }
    }
}
