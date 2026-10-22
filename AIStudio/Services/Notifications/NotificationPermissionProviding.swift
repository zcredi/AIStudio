enum NotificationPermission: Equatable, Sendable {
    case notDetermined
    case allowed
    /// Отсюда изменить его можно только в «Настройках».
    case denied
}

protocol NotificationPermissionProviding: Sendable {
    func currentPermission() async -> NotificationPermission
    /// Показывает системный запрос один раз; дальше возвращает сохранённый ответ.
    func requestPermission() async -> NotificationPermission
}
