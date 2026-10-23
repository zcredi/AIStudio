import Foundation
@testable import AIStudio

extension PaywallProduct {
    static let yearly = PaywallProduct(
        id: "year_39.99_nottrial",
        period: SubscriptionPeriod(unit: .year, value: 1),
        price: Decimal(3999) / 100,
        priceFormat: .currency(code: "USD").locale(Locale(identifier: "en_US"))
    )

    static let weekly = PaywallProduct(
        id: "week_4.99_nottrial",
        period: SubscriptionPeriod(unit: .week, value: 1),
        price: Decimal(499) / 100,
        priceFormat: .currency(code: "USD").locale(Locale(identifier: "en_US"))
    )
}
