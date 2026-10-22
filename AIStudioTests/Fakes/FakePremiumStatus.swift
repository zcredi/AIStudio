import Combine
@testable import AIStudio

@MainActor
final class FakePremiumStatus: PremiumStatusProviding {
    /// При `false` `waitUntilStatusIsKnown()` возвращается только при отмене, как при первом запуске без сети.
    var isStatusKnown = true

    var isPremium: Bool {
        get { premiumSubject.value }
        set { premiumSubject.send(newValue) }
    }

    var isPremiumPublisher: AnyPublisher<Bool, Never> {
        premiumSubject.eraseToAnyPublisher()
    }

    private let premiumSubject = CurrentValueSubject<Bool, Never>(false)

    func waitUntilStatusIsKnown() async {
        guard !isStatusKnown else { return }
        // Возвращается раньше, если ожидающую задачу отменили: другого выхода здесь нет.
        try? await Task.sleep(for: .seconds(3600))
    }
}
