import Foundation
@testable import AIStudio

extension PaywallProduct {
    static let yearly = PaywallProduct(
        id: "com.labs.fviu.yearly",
        period: SubscriptionPeriod(unit: .year, value: 1),
        price: Decimal(6999) / 100,
        priceFormat: .currency(code: "USD").locale(Locale(identifier: "en_US"))
    )

    static let monthly = PaywallProduct(
        id: "com.labs.fviu.monthly",
        period: SubscriptionPeriod(unit: .month, value: 1),
        price: Decimal(799) / 100,
        priceFormat: .currency(code: "USD").locale(Locale(identifier: "en_US"))
    )
}
