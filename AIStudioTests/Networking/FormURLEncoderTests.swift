import XCTest
@testable import AIStudio

final class FormURLEncoderTests: XCTestCase {
    func test_encode_withSeveralFields_joinsPairsWithAmpersand() {
        let body = FormURLEncoder.encode([
            URLQueryItem(name: "prompt", value: "cat"),
            URLQueryItem(name: "duration", value: "5"),
        ])

        XCTAssertEqual(String(decoding: body, as: UTF8.self), "prompt=cat&duration=5")
    }

    func test_encode_withSpaces_replacesThemWithPlus() {
        let body = FormURLEncoder.encode([URLQueryItem(name: "prompt", value: "a cat on a roof")])

        XCTAssertEqual(String(decoding: body, as: UTF8.self), "prompt=a+cat+on+a+roof")
    }

    func test_encode_withReservedCharacters_percentEncodesThem() {
        let body = FormURLEncoder.encode([URLQueryItem(name: "prompt", value: "1+1=2 & café?")])

        XCTAssertEqual(String(decoding: body, as: UTF8.self), "prompt=1%2B1%3D2+%26+caf%C3%A9%3F")
    }

    func test_encode_withNilValue_encodesEmptyValue() {
        let body = FormURLEncoder.encode([URLQueryItem(name: "seed", value: nil)])

        XCTAssertEqual(String(decoding: body, as: UTF8.self), "seed=")
    }
}
