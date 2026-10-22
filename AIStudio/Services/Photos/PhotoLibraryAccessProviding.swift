enum PhotoLibraryAccess: Equatable, Sendable {
    case notDetermined
    /// Полный или ограниченный доступ: пикер можно открыть.
    case granted
    case denied
}

protocol PhotoLibraryAccessProviding: Sendable {
    func currentAccess() -> PhotoLibraryAccess
    /// Показывает системный запрос, только пока доступ не определён.
    func requestAccess() async -> PhotoLibraryAccess
}
