import XCTest
@testable import AIStudio

final class ServerErrorBodyTests: XCTestCase {
    func test_message_withStringDetail_returnsDetail() {
        let data = Data(#"{"detail": "Insufficient balance for Dola chat"}"#.utf8)

        XCTAssertEqual(ServerErrorBody.message(in: data), "Insufficient balance for Dola chat")
    }

    func test_message_withValidationErrors_joinsMessages() {
        let data = Data(#"""
        {"detail": [
            {"loc": ["query", "user_id"], "msg": "Field required", "type": "missing"},
            {"loc": ["body", "message"], "msg": "String too long", "type": "string_too_long"}
        ]}
        """#.utf8)

        XCTAssertEqual(ServerErrorBody.message(in: data), "Field required\nString too long")
    }

    func test_message_withUnknownBody_returnsNil() {
        let data = Data("<html>Bad Gateway</html>".utf8)

        XCTAssertNil(ServerErrorBody.message(in: data))
    }
}
