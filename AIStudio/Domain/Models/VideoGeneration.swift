import Foundation

/// Видео, которое пользователь сгенерировал или генерирует. История показывает их от новых к старым.
struct VideoGeneration: Identifiable, Equatable, Codable, Sendable {
    // MARK: - Types

    enum State: String, Codable, Sendable {
        case inProgress
        case failed
        case ready
    }

    // MARK: - Properties

    let id: UUID
    let templateID: Int
    let templateName: String
    let format: VideoFormat
    let quality: VideoQuality
    let createdAt: Date
    var state: State
    /// Серверный ID после загрузки фото; с ним опрос продолжается после перезапуска.
    var remoteID: Int?
    /// Результат ещё не открывали.
    var isNew: Bool
    /// Причина последней неудачи; `nil`, пока генерация не упала.
    var failure: VideoGenerationError?
}
