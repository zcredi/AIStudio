import Combine
import Foundation

/// Держит сплэш, пока не известен статус подписки, чтобы следующий экран был правильным.
@MainActor
final class SplashViewModel {
    // MARK: - Types

    struct Timing {
        /// Не даёт сплэшу мелькнуть, когда всё уже есть в кэше.
        let minimumDuration: Duration
        /// Первый запуск без сети не должен зависать на сплэше.
        let timeout: Duration

        static let standard = Timing(minimumDuration: .seconds(1), timeout: .seconds(4))
    }

    enum Event: Equatable {
        case finished
    }

    // MARK: - Properties

    let events: AnyPublisher<Event, Never>

    private let premiumStatus: any PremiumStatusProviding
    private let timing: Timing
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var startTask: Task<Void, Never>?

    // MARK: - Init

    init(premiumStatus: any PremiumStatusProviding, timing: Timing = .standard) {
        self.premiumStatus = premiumStatus
        self.timing = timing
        events = eventSubject.eraseToAnyPublisher()
    }

    deinit {
        startTask?.cancel()
    }

    // MARK: - API

    @discardableResult
    func start() -> Task<Void, Never> {
        startTask?.cancel()
        let task = Task { [weak self, premiumStatus, timing] in
            async let minimumDelay: Void = Self.sleep(for: timing.minimumDuration)
            await Self.waitForStatus(of: premiumStatus, timeout: timing.timeout)
            await minimumDelay
            guard !Task.isCancelled else { return }
            self?.eventSubject.send(.finished)
        }
        startTask = task
        return task
    }

    // MARK: - Private

    private static func waitForStatus(of premiumStatus: any PremiumStatusProviding, timeout: Duration) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await premiumStatus.waitUntilStatusIsKnown() }
            group.addTask { await sleep(for: timeout) }
            await group.next()
            group.cancelAll()
        }
    }

    private static func sleep(for duration: Duration) async {
        // Отмена только сокращает ожидание, а обоим вызывающим это и нужно.
        try? await Task.sleep(for: duration)
    }
}
