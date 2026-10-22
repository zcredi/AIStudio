struct ChatReply: Equatable, Sendable {
    /// Сервер может присвоить новому чату свой ID; следующие сообщения уходят в него.
    let chatID: String
    let text: String
}
