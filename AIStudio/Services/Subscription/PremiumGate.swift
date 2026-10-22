@MainActor
final class PremiumGate: PremiumGating {
    // MARK: - Properties

    /// Показывает пейвол; задаётся `AppCoordinator`, который отвечает за навигацию.
    var onPaywallRequired: (@MainActor () -> Void)?

    private let premiumStatus: any PremiumStatusProviding

    // MARK: - Init

    init(premiumStatus: any PremiumStatusProviding) {
        self.premiumStatus = premiumStatus
    }

    // MARK: - PremiumGating

    func perform(_ action: @escaping @MainActor () -> Void) {
        guard premiumStatus.isPremium else {
            onPaywallRequired?()
            return
        }
        action()
    }
}
