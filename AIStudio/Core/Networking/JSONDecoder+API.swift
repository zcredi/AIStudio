import Foundation

extension JSONDecoder {
    /// Декодер для ответов API. Даты в ISO 8601 в том виде, как их пишет FastAPI: с дробными секундами
    /// или без, а время без часового пояса читается как UTC.
    static func api() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = APITimestamp.date(from: string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unsupported date format: \(string)"
                )
            }
            return date
        }
        return decoder
    }
}

// MARK: - APITimestamp

private enum APITimestamp {
    private static let withFractionalSeconds = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let withoutFractionalSeconds = Date.ISO8601FormatStyle()

    static func date(from string: String) -> Date? {
        let value = hasTimeZone(string) ? string : string + "Z"
        // Старые системы разбирают каждый вариант только своим стилем, поэтому второй — запасной.
        return (try? withFractionalSeconds.parse(value)) ?? (try? withoutFractionalSeconds.parse(value))
    }

    private static func hasTimeZone(_ string: String) -> Bool {
        guard let timeStart = string.firstIndex(of: "T") else { return false }
        let time = string[timeStart...]
        return time.hasSuffix("Z") || time.contains("+") || time.contains("-")
    }
}
