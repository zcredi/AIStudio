import OSLog
import UIKit

/// Text styles from the Figma type scale, named `<weight><size>`.
///
/// Each font scales with Dynamic Type relative to the closest system text style,
/// so labels need `adjustsFontForContentSizeCategory`.
enum Typography {
    static let bold34 = font(.bold, size: 34, relativeTo: .largeTitle)
    /// Figma adds 0.4 pt tracking to this style; apply it as `.kern` where the text is set.
    static let bold28 = font(.bold, size: 28, relativeTo: .title1)

    static let semibold20 = font(.semibold, size: 20, relativeTo: .title3)
    static let medium20 = font(.medium, size: 20, relativeTo: .title3)
    static let regular20 = font(.regular, size: 20, relativeTo: .title3)

    static let semibold16 = font(.semibold, size: 16, relativeTo: .callout)
    static let medium16 = font(.medium, size: 16, relativeTo: .callout)
    static let regular16 = font(.regular, size: 16, relativeTo: .callout)

    static let semibold14 = font(.semibold, size: 14, relativeTo: .subheadline)
    static let regular14 = font(.regular, size: 14, relativeTo: .subheadline)

    static let medium12 = font(.medium, size: 12, relativeTo: .caption1)
}

// MARK: - Private

private extension Typography {
    /// Inter faces bundled in `Resources/Fonts` and listed under `UIAppFonts`.
    enum Face: String {
        case regular = "Inter-Regular"
        case medium = "Inter-Medium"
        case semibold = "Inter-SemiBold"
        case bold = "Inter-Bold"

        var systemWeight: UIFont.Weight {
            switch self {
            case .regular:
                .regular
            case .medium:
                .medium
            case .semibold:
                .semibold
            case .bold:
                .bold
            }
        }
    }

    static let logger = Logger(category: "Typography")

    static func font(_ face: Face, size: CGFloat, relativeTo style: UIFont.TextStyle) -> UIFont {
        let base: UIFont
        if let inter = UIFont(name: face.rawValue, size: size) {
            base = inter
        } else {
            logger.fault("Font \(face.rawValue, privacy: .public) is not bundled, using the system font")
            base = .systemFont(ofSize: size, weight: face.systemWeight)
        }
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }
}
