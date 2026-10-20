import UIKit

/// Glass variants used in the app. Liquid Glass on iOS 26, a tinted system blur before that.
@MainActor
enum GlassMaterial {
    /// Bars, input fields and floating buttons over regular content.
    case regular
    /// Controls over media or gradients, where the backdrop has to stay visible.
    case clear

    // MARK: - API

    func makeEffect() -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            return UIGlassEffect(style: glassStyle)
        }
        return UIBlurEffect(style: .systemUltraThinMaterialDark)
    }

    /// Surface tint from the mockups, laid over the blur on systems without Liquid Glass.
    var fallbackTintColor: UIColor {
        switch self {
        case .regular:
            Palette.card.withAlphaComponent(0.4)
        case .clear:
            Palette.accent.withAlphaComponent(0.15)
        }
    }

    // MARK: - Private

    @available(iOS 26.0, *)
    private var glassStyle: UIGlassEffect.Style {
        switch self {
        case .regular:
            .regular
        case .clear:
            .clear
        }
    }
}
