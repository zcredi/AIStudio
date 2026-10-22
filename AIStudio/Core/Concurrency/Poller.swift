enum PollingError: Error, Equatable, Sendable {
    case timedOut
}

/// Повторяет проверку с backoff, пока она не вернёт значение.
struct Poller: Sendable {
    // MARK: - Properties

    private let policy: PollingPolicy

    // MARK: - Init

    init(policy: PollingPolicy) {
        self.policy = policy
    }

    // MARK: - API

    /// `check` возвращает `nil`, пока операция идёт. Бросает `PollingError.timedOut`, ошибку проверки,
    /// если неудач подряд больше, чем допускает политика, или `CancellationError`.
    func poll<Value: Sendable>(_ check: @Sendable () async throws -> Value?) async throws -> Value {
        let clock = ContinuousClock()
        let deadline = clock.now + policy.timeout
        var interval = policy.initialInterval
        var failures = 0

        while true {
            do {
                if let value = try await check() {
                    return value
                }
                failures = 0
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                failures += 1
                guard failures <= policy.maxConsecutiveFailures else { throw error }
            }

            guard clock.now + interval < deadline else { throw PollingError.timedOut }
            try await Task.sleep(for: interval)
            interval = min(interval * policy.backoffFactor, policy.maxInterval)
        }
    }
}
