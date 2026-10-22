import Foundation

/// Эндпоинты чата Dola. `user_id` и `app_id` добавляет `ClientIdentityInterceptor`.
enum DolaAPI {
    static func chats(limit: Int, offset: Int) -> Endpoint<[DolaChatDTO]> {
        .get("/dola/chats", queryItems: pagination(limit: limit, offset: offset))
    }

    static func messages(chatID: String, limit: Int, offset: Int) -> Endpoint<[DolaMessageDTO]> {
        .get("/dola/chats/\(chatID)/messages", queryItems: pagination(limit: limit, offset: offset))
    }

    static func sendMessage(_ request: DolaSendMessageRequestDTO, chatID: String) -> Endpoint<DolaSendMessageResponseDTO> {
        .post("/dola/chats/\(chatID)/messages", body: .json(request), timeout: RequestTimeout.generation)
    }

    private static func pagination(limit: Int, offset: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
    }
}
