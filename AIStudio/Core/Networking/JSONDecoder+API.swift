import Foundation

extension JSONDecoder {
    /// Decoder for API responses. Dates are ISO 8601 as FastAPI writes them: with or without
    /// fractional seconds, and naive timestamps without a time zone are read as UTC.
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
        // Older systems parse each variant with its own style only, so the second one is a fallback.
        return (try? withFractionalSeconds.parse(value)) ?? (try? withoutFractionalSeconds.parse(value))
    }

    private static func hasTimeZone(_ string: String) -> Bool {
        guard let timeStart = string.firstIndex(of: "T") else { return false }
        let time = string[timeStart...]
        return time.hasSuffix("Z") || time.contains("+") || time.contains("-")
    }
}
