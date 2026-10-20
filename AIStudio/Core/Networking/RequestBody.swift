import Foundation

enum RequestBody: Sendable {
    case json(any Encodable & Sendable)
    case formURLEncoded([URLQueryItem])
    case multipart(MultipartFormData)
}

// MARK: - Encoding

extension RequestBody {
    func encoded() throws -> (data: Data, contentType: String) {
        switch self {
        case .json(let value):
            (try JSONEncoder().encode(value), "application/json")
        case .formURLEncoded(let fields):
            (FormURLEncoder.encode(fields), "application/x-www-form-urlencoded")
        case .multipart(let formData):
            (formData.encoded(), formData.contentType)
        }
    }
}
