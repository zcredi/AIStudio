@MainActor
protocol TextCopying: AnyObject {
    /// Возвращает `false`, если текст не попал в буфер обмена.
    func copy(_ text: String) -> Bool
}
