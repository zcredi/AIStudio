import Foundation

/// Error payload returned by the API: either `{"detail": "..."}` or a FastAPI validation
/// error `{"detail": [{"loc": [...], "msg": "...", "type": "..."}]}`.
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

    /// Message from an error response, or `nil` when the body has another shape.
    static func message(in data: Data) -> String? {
        // An unknown error body is not a failure of its own; the status code still describes it.
        try? JSONDecoder().decode(ServerErrorBody.self, from: data).message
    }
}
