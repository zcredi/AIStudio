import Foundation

/// `DolaChatResponse` в спеке API.
struct DolaChatDTO: Decodable, Sendable {
    let chatID: String
    let title: String?
    let updatedAt: Date
    let lastMessagePreview: String?

    private enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case title
        case updatedAt = "updated_at"
        case lastMessagePreview = "last_message_preview"
    }
}

/// `DolaMessageResponse` в спеке API.
struct DolaMessageDTO: Decodable, Sendable {
    let role: String
    let content: String
    let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case role
        case content
        case createdAt = "created_at"
    }
}

/// `SendDolaMessageRequest` в спеке API.
struct DolaSendMessageRequestDTO: Encodable, Sendable {
    let message: String
}

/// `SendDolaMessageResponse` в спеке API.
struct DolaSendMessageResponseDTO: Decodable, Sendable {
    let chatID: String
    let assistantMessage: String

    private enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case assistantMessage = "assistant_message"
    }
}
