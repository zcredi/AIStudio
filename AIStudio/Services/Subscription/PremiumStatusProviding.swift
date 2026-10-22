import Combine

@MainActor
protocol PremiumStatusProviding: AnyObject, Sendable {
    var isPremium: Bool { get }
    /// Отдаёт текущее значение при подписке и каждое изменение после покупки, восстановления или продления.
    var isPremiumPublisher: AnyPublisher<Bool, Never> { get }
    /// Возвращается, когда статус подписки загружен или восстановлен из кэша.
    /// При первом запуске без доступа к магазину не вернётся никогда, поэтому вызывающие добавляют таймаут.
    func waitUntilStatusIsKnown() async
}
