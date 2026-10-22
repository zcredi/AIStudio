import Foundation

/// Вариант покупки в том виде, в каком его показывает пейвол: цена за неделю, полная цена и плашка выгоды.
struct PaywallPlan: Identifiable, Equatable, Sendable {
    let id: PaywallProduct.ID
    /// Период и цена за неделю, например «Year $1.35».
    let title: String
    /// Цена за весь период, например «$69.99».
    let fullPrice: String
    /// «SAVE 80%» на плане с самой низкой ценой за неделю, `nil` на остальных.
    let savings: String?
}

// MARK: - Building

extension PaywallPlan {
    /// Сохраняет порядок продуктов и отмечает план, самый дешёвый за неделю.
    static func plans(for products: [PaywallProduct]) -> [PaywallPlan] {
        let bestValue = bestValueOffer(in: products)
        return products.map { product in
            PaywallPlan(
                id: product.id,
                title: "\(product.period.name) \(product.weeklyPrice.formatted(product.priceFormat))",
                fullPrice: product.price.formatted(product.priceFormat),
                savings: product.id == bestValue?.productID ? bestValue?.badge : nil
            )
        }
    }

    /// Процент на плашке задан макетом и не считается из цен.
    private static let advertisedSavingsPercent = 80

    private static func bestValueOffer(in products: [PaywallProduct]) -> (productID: PaywallProduct.ID, badge: String)? {
        guard
            products.count > 1,
            let cheapest = products.min(by: { $0.weeklyPrice < $1.weeklyPrice })
        else {
            return nil
        }
        return (cheapest.id, String(localized: "SAVE \(advertisedSavingsPercent)%"))
    }
}

// MARK: - Private

private extension PaywallProduct {
    var weeklyPrice: Decimal {
        price / period.weeks
    }
}

private extension SubscriptionPeriod {
    var name: String {
        switch unit {
        case .day:
            value == 1 ? String(localized: "Day") : String(localized: "\(value) Days")
        case .week:
            value == 1 ? String(localized: "Week") : String(localized: "\(value) Weeks")
        case .month:
            value == 1 ? String(localized: "Month") : String(localized: "\(value) Months")
        case .year:
            value == 1 ? String(localized: "Year") : String(localized: "\(value) Years")
        }
    }
}
