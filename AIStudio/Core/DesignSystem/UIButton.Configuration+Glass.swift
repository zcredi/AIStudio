import UIKit

extension UIButton.Configuration {
    /// Стеклянная кнопка на iOS 26; на более ранних версиях — размытая капсула с тоном из макетов.
    @MainActor
    static func adaptiveGlass() -> UIButton.Configuration {
        var configuration: UIButton.Configuration
        if #available(iOS 26.0, *) {
            configuration = .glass()
        } else {
            configuration = .plain()
            configuration.background.visualEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            configuration.background.backgroundColor = Palette.accent.withAlphaComponent(0.08)
            configuration.cornerStyle = .capsule
        }
        configuration.baseForegroundColor = Palette.textPrimary
        return configuration
    }
}
