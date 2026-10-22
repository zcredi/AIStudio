import Foundation

/// Кодирует поля как `application/x-www-form-urlencoded` по спецификации WHATWG URL:
/// всё, кроме `A-Z a-z 0-9 - . _ *`, кодируется через проценты, а пробелы становятся `+`.
enum FormURLEncoder {
    // MARK: - API

    static func encode(_ fields: [URLQueryItem]) -> Data {
        Data(encodedString(fields).utf8)
    }

    /// То же кодирование в виде строки; подходит и как query в URL.
    static func encodedString(_ fields: [URLQueryItem]) -> String {
        fields
            .map { "\(escape($0.name))=\(escape($0.value ?? ""))" }
            .joined(separator: "&")
    }

    // MARK: - Private

    private static let unreservedCharacters = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._* "
    )

    private static func escape(_ string: String) -> String {
        // Percent-кодирование падает только на непарных суррогатах, которых не бывает в Swift String.
        let escaped = string.addingPercentEncoding(withAllowedCharacters: unreservedCharacters) ?? string
        return escaped.replacingOccurrences(of: " ", with: "+")
    }
}
