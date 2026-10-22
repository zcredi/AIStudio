import Combine
import Foundation

@MainActor
final class MainViewModel {
    // MARK: - Types

    struct State: Equatable {
        /// Кнопка PRO ведёт на пейвол, поэтому подписчики её не видят.
        var isProButtonVisible = true
    }

    // MARK: - Properties

    @Published private(set) var state = State()

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(premiumStatus: any PremiumStatusProviding) {
        premiumStatus.isPremiumPublisher
            .sink { [weak self] isPremium in
                self?.update { $0.isProButtonVisible = !isPremium }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private

    private func update(_ change: (inout State) -> Void) {
        var next = state
        change(&next)
        state = next
    }
}
