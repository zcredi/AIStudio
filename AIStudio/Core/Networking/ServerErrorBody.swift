import Foundation

/// Тело ошибки от API: либо `{"detail": "..."}`, либо ошибка валидации FastAPI
/// `{"detail": [{"loc": [...], "msg": "...", "type": "..."}]}`.
struct ServerErrorBody: Decodable, Sendable {
    // MARK: - Types

    private enum CodingKeys: String, CodingKey {
        case detail
    }

    private struct ValidationIssue: Decodable {
        let msg: String
    }

    // MARK: - Properties

    let message: String

    // MARK: - Init

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let detail = try? container.decode(String.self, forKey: .detail) {
            message = detail
        } else {
            let issues = try container.decode([ValidationIssue].self, forKey: .detail)
            message = issues.map(\.msg).joined(separator: "\n")
        }
    }

    // MARK: - API

    /// Сообщение из тела ошибки или `nil`, если у тела другая форма.
    static func message(in data: Data) -> String? {
        // Неизвестное тело ошибки само по себе не сбой: статус-код и так её описывает.
        try? JSONDecoder().decode(ServerErrorBody.self, from: data).message
    }
}
