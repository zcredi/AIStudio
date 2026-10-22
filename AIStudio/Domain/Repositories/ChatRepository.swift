protocol ChatRepository: Sendable {
    func chats() async throws -> [Chat]
    func messages(inChat chatID: String) async throws -> [ChatMessage]
    /// Начинает новый чат, если `chatID` ещё не использовался.
    func sendMessage(_ text: String, toChat chatID: String) async throws -> ChatReply
}
