/// Текстовая версия переписки для системного окна «Поделиться».
enum ChatTranscript {
    static func text(of messages: [ChatMessage]) -> String {
        messages
            .map { "\(author(of: $0)):\n\($0.text)" }
            .joined(separator: "\n\n")
    }

    private static func author(of message: ChatMessage) -> String {
        switch message.role {
        case .user:
            String(localized: "You")
        case .assistant:
            String(localized: "AI Chat")
        }
    }
}
