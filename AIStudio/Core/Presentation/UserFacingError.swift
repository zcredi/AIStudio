import Foundation

/// Ошибка, превращённая в текст для пользователя. Слои описывают свои ошибки через `LocalizedError`.
struct UserFacingError: Error, Equatable, Sendable {
    // MARK: - Properties

    let message: String

    // MARK: - Init

    init(message: String) {
        self.message = message
    }

    /// Для отмены возвращает `nil`: отмену никогда не показываем.
    init?(_ error: any Error) {
        if error is CancellationError {
            return nil
        }
        let description = (error as? LocalizedError)?.errorDescription
        message = description ?? String(localized: "Something went wrong. Please try again.")
    }
}
