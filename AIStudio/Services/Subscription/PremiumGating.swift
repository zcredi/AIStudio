@MainActor
protocol PremiumGating: AnyObject {
    /// Выполняет `action` для подписчиков; остальные видят пейвол, и больше ничего не происходит.
    func perform(_ action: @escaping @MainActor () -> Void)
}
