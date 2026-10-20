import UIKit
import XCTest
@testable import AIStudio

final class TypographyTests: XCTestCase {
    func test_styles_useBundledInter() {
        let styles: [UIFont] = [
            Typography.bold34, Typography.bold28,
            Typography.semibold20, Typography.medium20, Typography.regular20,
            Typography.semibold16, Typography.medium16, Typography.regular16,
            Typography.semibold14, Typography.regular14,
            Typography.medium12,
        ]

        for font in styles {
            XCTAssertEqual(font.familyName, "Inter", "\(font.fontName) is not Inter")
        }
    }
}
