import Foundation

enum VideoSavingError: Error, Equatable, Sendable {
    case accessDenied
    case failed
}

protocol VideoSaving: Sendable {
    /// Добавляет видеофайл в медиатеку пользователя.
    func saveVideo(at fileURL: URL) async throws
}
