import Foundation

enum RequestTimeout {
    static let standard: TimeInterval = 30
    /// Операции ИИ держат соединение открытым, пока модель не ответит.
    static let generation: TimeInterval = 120
}
