import Foundation

/// Собирает тело `multipart/form-data` (RFC 7578).
struct MultipartFormData: Sendable {
    // MARK: - Types

    private struct Part: Sendable {
        let headers: [String]
        let content: Data
    }

    // MARK: - Properties

    let boundary: String

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    private var parts: [Part] = []

    // MARK: - Init

    init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    // MARK: - API

    mutating func append(_ value: String, name: String) {
        let headers = ["Content-Disposition: form-data; name=\"\(Self.quoted(name))\""]
        parts.append(Part(headers: headers, content: Data(value.utf8)))
    }

    mutating func append(_ file: Data, name: String, fileName: String, mimeType: String) {
        let headers = [
            "Content-Disposition: form-data; name=\"\(Self.quoted(name))\"; filename=\"\(Self.quoted(fileName))\"",
            "Content-Type: \(mimeType)",
        ]
        parts.append(Part(headers: headers, content: file))
    }

    func encoded() -> Data {
        var body = Data()
        for part in parts {
            body.append(line: "--\(boundary)")
            part.headers.forEach { body.append(line: $0) }
            body.append(line: "")
            body.append(part.content)
            body.append(line: "")
        }
        body.append(line: "--\(boundary)--")
        return body
    }

    // MARK: - Private

    /// Экранирует символы, которые сломали бы параметр заголовка в кавычках, как это делают браузеры.
    private static func quoted(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\"", with: "%22")
            .replacingOccurrences(of: "\r", with: "%0D")
            .replacingOccurrences(of: "\n", with: "%0A")
    }
}

// MARK: - Data

private extension Data {
    mutating func append(line: String) {
        append(Data("\(line)\r\n".utf8))
    }
}
