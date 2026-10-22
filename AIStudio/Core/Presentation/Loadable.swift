/// Данные экрана: ещё загружаются, готовы или не загрузились с сообщением для пользователя.
/// Пустой результат — это `loaded` с пустым значением; как его показать, решает экран.
enum Loadable<Value> {
    case loading
    case loaded(Value)
    case failed(UserFacingError)

    var value: Value? {
        guard case .loaded(let value) = self else { return nil }
        return value
    }
}

extension Loadable: Equatable where Value: Equatable {}

extension Loadable: Sendable where Value: Sendable {}
