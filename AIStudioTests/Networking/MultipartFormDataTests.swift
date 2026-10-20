import XCTest
@testable import AIStudio

final class MultipartFormDataTests: XCTestCase {
    func test_contentType_includesBoundary() {
        let formData = MultipartFormData(boundary: "XYZ")

        XCTAssertEqual(formData.contentType, "multipart/form-data; boundary=XYZ")
    }

    func test_encoded_withTextAndFile_writesPartsInOrder() {
        // Given
        var formData = MultipartFormData(boundary: "XYZ")
        formData.append("42", name: "template_id")
        formData.append(Data("JPEG".utf8), name: "image", fileName: "photo.jpg", mimeType: "image/jpeg")

        // When
        let body = String(decoding: formData.encoded(), as: UTF8.self)

        // Then
        let expected = [
            "--XYZ",
            "Content-Disposition: form-data; name=\"template_id\"",
            "",
            "42",
            "--XYZ",
            "Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"",
            "Content-Type: image/jpeg",
            "",
            "JPEG",
            "--XYZ--",
            "",
        ].joined(separator: "\r\n")
        XCTAssertEqual(body, expected)
    }

    func test_encoded_withQuoteInFileName_escapesIt() {
        var formData = MultipartFormData(boundary: "XYZ")
        formData.append(Data(), name: "image", fileName: "my \"best\".jpg", mimeType: "image/jpeg")

        let body = String(decoding: formData.encoded(), as: UTF8.self)

        XCTAssertTrue(body.contains("filename=\"my %22best%22.jpg\""))
    }

    func test_encoded_withoutParts_writesOnlyClosingBoundary() {
        let formData = MultipartFormData(boundary: "XYZ")

        XCTAssertEqual(String(decoding: formData.encoded(), as: UTF8.self), "--XYZ--\r\n")
    }
}
