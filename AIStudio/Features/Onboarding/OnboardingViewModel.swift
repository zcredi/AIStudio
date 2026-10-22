import Combine
import Foundation

@MainActor
final class OnboardingViewModel {
    // MARK: - Types

    struct State: Equatable {
        let pages = OnboardingPage.allCases
        var currentPageIndex = 0
    }

    enum Event: Equatable {
        case finished
    }

    // MARK: - Properties

    @Published private(set) var state = State()
    let events: AnyPublisher<Event, Never>

    private let progressStore: any OnboardingProgressStoring
    private let eventSubject = PassthroughSubject<Event, Never>()

    // MARK: - Init

    init(progressStore: any OnboardingProgressStoring) {
        self.progressStore = progressStore
        events = eventSubject.eraseToAnyPublisher()
    }

    // MARK: - API

    /// Вызывается, когда пользователь свайпает на другую страницу.
    func showPage(at index: Int) {
        guard state.pages.indices.contains(index), index != state.currentPageIndex else { return }
        update { $0.currentPageIndex = index }
    }

    /// Переходит на следующую страницу или завершает онбординг на последней.
    func continueTapped() {
        let nextIndex = state.currentPageIndex + 1
        guard state.pages.indices.contains(nextIndex) else {
            finish()
            return
        }
        update { $0.currentPageIndex = nextIndex }
    }

    // MARK: - Private

    private func update(_ change: (inout State) -> Void) {
        var next = state
        change(&next)
        state = next
    }

    private func finish() {
        progressStore.isOnboardingCompleted = true
        eventSubject.send(.finished)
    }
}
