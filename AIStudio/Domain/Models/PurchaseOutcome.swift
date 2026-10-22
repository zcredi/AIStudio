enum PurchaseOutcome: Equatable, Sendable {
    case purchased
    case cancelled
    /// Ожидает подтверждения (Ask to Buy); доступ придёт позже через обновление статуса.
    case pending
}
