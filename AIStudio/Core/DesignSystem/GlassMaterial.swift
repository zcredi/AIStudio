import UIKit

/// Варианты стекла в приложении. Liquid Glass на iOS 26, до неё — тонированный системный блюр.
@MainActor
enum GlassMaterial {
    /// Панели, поля ввода и плавающие кнопки поверх обычного контента.
    case regular
    /// Контролы поверх медиа или градиентов, где фон должен оставаться видимым.
    case clear
    /// Меню, которые всплывают поверх контента и должны читаться на любом фоне.
    case menu

    // MARK: - API

    func makeEffect() -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: glassStyle)
            effect.tintColor = glassTintColor
            return effect
        }
        return UIBlurEffect(style: .systemUltraThinMaterialDark)
    }

    /// Тон поверхности из макетов, который кладётся поверх блюра на системах без Liquid Glass.
    var fallbackTintColor: UIColor {
        switch self {
        case .regular:
            Palette.card.withAlphaComponent(0.4)
        case .clear:
            Palette.accent.withAlphaComponent(0.15)
        case .menu:
            Palette.card.withAlphaComponent(0.8)
        }
    }

    // MARK: - Private

    /// Меню показывают текст поверх любого контента, поэтому их стекло темнее панелей из макета.
    @available(iOS 26.0, *)
    private var glassTintColor: UIColor? {
        self == .menu ? Palette.card.withAlphaComponent(0.6) : nil
    }

    @available(iOS 26.0, *)
    private var glassStyle: UIGlassEffect.Style {
        switch self {
        case .regular, .menu:
            .regular
        case .clear:
            .clear
        }
    }
}
