import OSLog
import UIKit

/// Стили текста из шкалы Figma с именами вида `<weight><size>`.
///
/// Каждый шрифт масштабируется с Dynamic Type относительно ближайшего системного стиля,
/// поэтому лейблам нужен `adjustsFontForContentSizeCategory`.
enum Typography {
    static let bold34 = font(.bold, size: 34, relativeTo: .largeTitle)
    /// В Figma у этого стиля трекинг 0.4 pt; задаётся через `.kern` там, где выставляется текст.
    static let bold28 = font(.bold, size: 28, relativeTo: .title1)

    static let semibold20 = font(.semibold, size: 20, relativeTo: .title3)
    /// Заголовки навигации; есть в макетах, хотя в шкале шрифтов их нет.
    static let semibold18 = font(.semibold, size: 18, relativeTo: .headline)
    static let medium20 = font(.medium, size: 20, relativeTo: .title3)
    static let regular20 = font(.regular, size: 20, relativeTo: .title3)

    static let bold16 = font(.bold, size: 16, relativeTo: .callout)
    static let semibold16 = font(.semibold, size: 16, relativeTo: .callout)
    static let medium16 = font(.medium, size: 16, relativeTo: .callout)
    static let regular16 = font(.regular, size: 16, relativeTo: .callout)

    static let semibold14 = font(.semibold, size: 14, relativeTo: .subheadline)
    static let medium14 = font(.medium, size: 14, relativeTo: .subheadline)
    static let regular14 = font(.regular, size: 14, relativeTo: .subheadline)

    /// Подписи на карточках видео в истории; есть в макетах, хотя в шкале шрифтов их нет.
    static let semibold13 = font(.semibold, size: 13, relativeTo: .footnote)
    static let medium13 = font(.medium, size: 13, relativeTo: .footnote)

    static let medium12 = font(.medium, size: 12, relativeTo: .caption1)
    static let regular12 = font(.regular, size: 12, relativeTo: .caption1)

    /// Мелкий текст, который в макетах набран SF Pro, а не Inter, например подписи пейвола и юридические ссылки.
    static let systemRegular12 = UIFont.preferredFont(forTextStyle: .caption1)
    static let systemRegular11 = UIFont.preferredFont(forTextStyle: .caption2)
}

// MARK: - Private

private extension Typography {
    /// Начертания Inter из `Resources/Fonts`, перечисленные в `UIAppFonts`.
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
