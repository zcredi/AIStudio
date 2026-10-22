struct Paywall: Equatable, Sendable {
    /// Продукты в порядке, заданном в дашборде подписок.
    let products: [PaywallProduct]
}
