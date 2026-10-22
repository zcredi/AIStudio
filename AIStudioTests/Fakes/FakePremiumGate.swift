@testable import AIStudio

@MainActor
final class FakePremiumGate: PremiumGating {
    var isPremium = true
    private(set) var paywallRequestCount = 0

    func perform(_ action: @escaping @MainActor () -> Void) {
        guard isPremium else {
            paywallRequestCount += 1
            return
        }
        action()
    }
}
