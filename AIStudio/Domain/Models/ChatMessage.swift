import Foundation

struct ChatMessage: Identifiable, Equatable, Sendable {
    enum Role: Equatable, Sendable {
        case user
        case assistant
    }

    /// Стабилен в пределах одного загруженного диалога; сам API сообщения не идентифицирует.
    let id: String
    let role: Role
    let text: String
    let createdAt: Date
}
