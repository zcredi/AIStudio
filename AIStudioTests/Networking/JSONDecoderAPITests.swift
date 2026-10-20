import XCTest
@testable import AIStudio

final class JSONDecoderAPITests: XCTestCase {
    private struct Payload: Decodable {
        let createdAt: Date

        private enum CodingKeys: String, CodingKey {
            case createdAt = "created_at"
        }
    }

    /// 2026-03-26 12:34:56 UTC.
    private let referenceSeconds: TimeInterval = 1_774_528_496

    func test_decode_withMicroseconds_keepsFraction() throws {
        let date = try decodeDate("2026-03-26T12:34:56.123456Z")

        XCTAssertEqual(date.timeIntervalSince1970, referenceSeconds + 0.123456, accuracy: 0.001)
    }

    func test_decode_withoutFraction_parsesWholeSeconds() throws {
        let date = try decodeDate("2026-03-26T12:34:56Z")

        XCTAssertEqual(date.timeIntervalSince1970, referenceSeconds)
    }

    func test_decode_withOffset_convertsToUTC() throws {
        let date = try decodeDate("2026-03-26T15:34:56+03:00")

        XCTAssertEqual(date.timeIntervalSince1970, referenceSeconds)
    }

    func test_decode_withoutTimeZone_treatsAsUTC() throws {
        let date = try decodeDate("2026-03-26T12:34:56.5")

        XCTAssertEqual(date.timeIntervalSince1970, referenceSeconds + 0.5, accuracy: 0.001)
    }

    func test_decode_withInvalidDate_throws() {
        XCTAssertThrowsError(try decodeDate("yesterday"))
    }

    // MARK: - Private

    private func decodeDate(_ string: String) throws -> Date {
        let json = Data(#"{"created_at": "\#(string)"}"#.utf8)
        return try JSONDecoder.api().decode(Payload.self, from: json).createdAt
    }
}
