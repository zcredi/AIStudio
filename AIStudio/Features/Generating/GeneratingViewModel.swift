import Combine
import Foundation

/// Следит за одной генерацией, пока открыт её экран. Уход с экрана генерацию не останавливает.
@MainActor
final class GeneratingViewModel {
    // MARK: - Types

    enum State: Equatable {
        case generating
        case failed(UserFacingError)
    }

    enum Event: Equatable {
        case openResult(VideoGeneration)
    }

    // MARK: - Properties

    @Published private(set) var state = State.generating
    let events: AnyPublisher<Event, Never>

    private let generationID: VideoGeneration.ID
    private let generator: any VideoGenerating
    private let premiumGate: any PremiumGating
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var subscription: AnyCancellable?
    private var hasOpenedResult = false

    // MARK: - Init

    init(generationID: VideoGeneration.ID, generator: any VideoGenerating, premiumGate: any PremiumGating) {
        self.generationID = generationID
        self.generator = generator
        self.premiumGate = premiumGate
        events = eventSubject.eraseToAnyPublisher()
    }

    // MARK: - API

    /// Вызывать, когда экран уже подписан на `events`: готовая генерация сразу открывает результат.
    func start() {
        guard subscription == nil else { return }
        subscription = generator.generationsPublisher
            .compactMap { [generationID] in $0.first { $0.id == generationID } }
            .sink { [weak self] in self?.show($0) }
    }

    /// Повтор тратит кредиты, как новая генерация, поэтому это тоже премиум-действие.
    func retryTapped() {
        premiumGate.perform { [generator, generationID] in
            generator.retry(generationID)
        }
    }

    // MARK: - Private

    private func show(_ generation: VideoGeneration) {
        switch generation.state {
        case .inProgress:
            state = .generating
        case .failed:
            let failure = generation.failure ?? .unknown
            state = .failed(UserFacingError(message: failure.localizedDescription))
        case .ready:
            guard !hasOpenedResult else { return }
            hasOpenedResult = true
            eventSubject.send(.openResult(generation))
        }
    }
}
