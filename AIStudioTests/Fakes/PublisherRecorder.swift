import Combine

/// Собирает всё, что отдаёт publisher, чтобы тест мог проверить это после.
@MainActor
final class PublisherRecorder<Value> {
    private(set) var values: [Value] = []
    private var cancellable: AnyCancellable?

    init(_ publisher: AnyPublisher<Value, Never>) {
        cancellable = publisher.sink { [weak self] value in
            self?.values.append(value)
        }
    }
}
