import Foundation

struct SubscriptionPeriod: Equatable, Sendable {
    enum Unit: Equatable, Sendable {
        case day
        case week
        case month
        case year
    }

    let unit: Unit
    let value: Int

    /// Длина периода в неделях, чтобы сравнивать планы по цене за неделю.
    var weeks: Decimal {
        let count = Decimal(value)
        switch unit {
        case .day:
            return count / 7
        case .week:
            return count
        case .month:
            return count * 52 / 12
        case .year:
            return count * 52
        }
    }
}
