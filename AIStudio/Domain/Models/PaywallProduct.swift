import Foundation

struct PaywallProduct: Identifiable, Equatable, Sendable {
    let id: String
    let period: SubscriptionPeriod
    let price: Decimal
    /// Форматирует суммы в валюте и локали магазина.
    let priceFormat: Decimal.FormatStyle.Currency
}
