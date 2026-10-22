import Foundation

struct DolaChatRepository: ChatRepository {
    // MARK: - Types

    private enum Page {
        static let chatsLimit = 100
        static let messagesLimit = 200
    }

    // MARK: - Properties

    private let client: any APIClient

    // MARK: - Init

    init(client: any APIClient) {
        self.client = client
    }

    // MARK: - ChatRepository

    func chats() async throws -> [Chat] {
        try await client.send(DolaAPI.chats(limit: Page.chatsLimit, offset: 0)).map(Chat.init)
    }

    func messages(inChat chatID: String) async throws -> [ChatMessage] {
        let messages = try await client.send(DolaAPI.messages(chatID: chatID, limit: Page.messagesLimit, offset: 0))
        return messages.enumerated().compactMap { index, dto in
            ChatMessage(dto, id: "\(chatID)-\(index)")
        }
    }

    func sendMessage(_ text: String, toChat chatID: String) async throws -> ChatReply {
        let response = try await client.send(DolaAPI.sendMessage(DolaSendMessageRequestDTO(message: text), chatID: chatID))
        return ChatReply(chatID: response.chatID, text: response.assistantMessage)
    }
}

// MARK: - Mapping

private extension Chat {
    init(_ dto: DolaChatDTO) {
        self.init(id: dto.chatID, title: dto.title, updatedAt: dto.updatedAt, lastMessagePreview: dto.lastMessagePreview)
    }
}

private extension ChatMessage {
    /// Возвращает `nil` для ролей, которые чат не показывает, например для системных сообщений.
    init?(_ dto: DolaMessageDTO, id: String) {
        switch dto.role {
        case "user":
            self.init(id: id, role: .user, text: dto.content, createdAt: dto.createdAt)
        case "assistant":
            self.init(id: id, role: .assistant, text: dto.content, createdAt: dto.createdAt)
        default:
            return nil
        }
    }
}
