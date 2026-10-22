/// Строка переписки в том виде, в каком её показывает чат.
enum ChatItem: Identifiable, Equatable, Sendable {
    case message(ChatMessage, canRegenerate: Bool)
    /// Ассистент пишет ответ.
    case typing
    /// Последний запрос не удался; строка предлагает повторить.
    case failure(UserFacingError)

    var id: String {
        switch self {
        case .message(let message, _):
            message.id
        case .typing:
            "typing"
        case .failure:
            "failure"
        }
    }
}
