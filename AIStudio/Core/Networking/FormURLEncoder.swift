import Foundation

/// Encodes fields as `application/x-www-form-urlencoded` following the WHATWG URL spec:
/// everything except `A-Z a-z 0-9 - . _ *` is percent-encoded and spaces become `+`.
enum FormURLEncoder {
    // MARK: - API

    static func encode(_ fields: [URLQueryItem]) -> Data {
        let body = fields
            .map { "\(escape($0.name))=\(escape($0.value ?? ""))" }
            .joined(separator: "&")
        return Data(body.utf8)
    }

    // MARK: - Private

    private static let unreservedCharacters = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._* "
    )

    private static func escape(_ string: String) -> String {
        // Percent-encoding fails only on unpaired surrogates, which a Swift String cannot hold.
        let escaped = string.addingPercentEncoding(withAllowedCharacters: unreservedCharacters) ?? string
        return escaped.replacingOccurrences(of: " ", with: "+")
    }
}
