import UIKit

extension UIButton.Configuration {
    /// Glass button on iOS 26; on earlier versions a blurred capsule with the tint from the mockups.
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
