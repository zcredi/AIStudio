import Foundation

/// Почему генерация не удалась. Хранится в истории, поэтому экран генерации
/// объясняет причину и после перезапуска приложения.
enum VideoGenerationError: String, Error, Equatable, Codable, Sendable {
    /// Сервер сообщил, что не смог отрисовать видео.
    case renderingFailed
    case offline
    /// HTTP 402: на аккаунте закончились кредиты.
    case insufficientCredits
    /// Сервер не успел отрисовать видео за время, которое приложение готово ждать.
    case timedOut
    /// Приложение закрылось раньше, чем фото успело загрузиться.
    case interrupted
    case unknown
}

// MARK: - LocalizedError

extension VideoGenerationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .renderingFailed:
            String(localized: "The video couldn't be generated. Please try again.")
        case .offline:
            String(localized: "No internet connection. Check your network and try again.")
        case .insufficientCredits:
            String(localized: "Not enough credits to generate a video.")
        case .timedOut:
            String(localized: "Generation is taking too long. Please try again.")
        case .interrupted:
            String(localized: "Generation was interrupted. Please try again.")
        case .unknown:
            String(localized: "Something went wrong. Please try again.")
        }
    }
}
