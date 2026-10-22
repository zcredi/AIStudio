import XCTest
@testable import AIStudio

final class ImageCropperTests: XCTestCase {
    func test_centeredRect_forWiderImage_cropsSides() {
        let rect = ImageCropper.centeredRect(in: CGSize(width: 400, height: 300), aspectRatio: 1)

        XCTAssertEqual(rect, CGRect(x: 50, y: 0, width: 300, height: 300))
    }

    func test_centeredRect_forTallerImage_cropsTopAndBottom() {
        let rect = ImageCropper.centeredRect(in: CGSize(width: 900, height: 900), aspectRatio: 16.0 / 9.0)

        XCTAssertEqual(rect, CGRect(x: 0, y: 197, width: 900, height: 506))
    }

    func test_jpegData_downsamplesBeforeCropping() async throws {
        let data = TestImage.jpegData(width: 400, height: 200)

        let cropped = try await ImageCropper.jpegData(from: data, croppedTo: 9.0 / 16.0, maxPixelSize: 100)

        XCTAssertEqual(TestImage.pixelSize(of: cropped), CGSize(width: 28, height: 50))
    }
}
