@MainActor
protocol SubscriptionPurchasing: AnyObject {
    /// Бросает `SubscriptionError.paywallUnavailable`, если предложить нечего.
    func loadPaywall() async throws -> Paywall
    func purchase(_ product: PaywallProduct) async throws -> PurchaseOutcome
    /// Успешно, только если после этого премиум-доступ активен.
    func restorePurchases() async throws
}
