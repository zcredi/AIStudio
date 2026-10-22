import Foundation
@testable import AIStudio

actor FakeChatRepository: ChatRepository {
    private(set) var sentMessages: [(text: String, chatID: String)] = []
    private var replyResult: Result<String, any Error>
    private var replyChatID: String?
    private var history: [ChatMessage]
    private var chatsResult: Result<[Chat], any Error>

    init(
        reply: Result<String, any Error> = .success("Hello!"),
        replyChatID: String? = nil,
        history: [ChatMessage] = [],
        chats: Result<[Chat], any Error> = .success([])
    ) {
        replyResult = reply
        self.replyChatID = replyChatID
        self.history = history
        chatsResult = chats
    }

    func setReply(_ result: Result<String, any Error>) {
        replyResult = result
    }

    func chats() async throws -> [Chat] {
        try chatsResult.get()
    }

    func messages(inChat chatID: String) async throws -> [ChatMessage] {
        history
    }

    func sendMessage(_ text: String, toChat chatID: String) async throws -> ChatReply {
        sentMessages.append((text, chatID))
        return ChatReply(chatID: replyChatID ?? chatID, text: try replyResult.get())
    }
}
