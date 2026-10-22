/// Как часто и как долго `Poller` повторяет проверку.
struct PollingPolicy: Sendable {
    let initialInterval: Duration
    let maxInterval: Duration
    /// Каждое ожидание — предыдущее, умноженное на этот коэффициент, но не больше `maxInterval`.
    let backoffFactor: Double
    let timeout: Duration
    /// Сколько неудачных проверок подряд допускается, чтобы короткий обрыв сети не прерывал долгую операцию.
    let maxConsecutiveFailures: Int
}

extension PollingPolicy {
    /// PixVerse рендерит ролик примерно за минуту; таймаут оставляет запас на загруженную очередь.
    static let videoGeneration = PollingPolicy(
        initialInterval: .seconds(3),
        maxInterval: .seconds(10),
        backoffFactor: 1.5,
        timeout: .seconds(600),
        maxConsecutiveFailures: 3
    )
}
