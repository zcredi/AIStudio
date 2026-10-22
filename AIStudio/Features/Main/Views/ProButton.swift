import UIKit

/// Градиентная капсула «PRO» в шапке главной; видна только пользователям без подписки.
final class ProButton: UIButton {
    // MARK: - Types

    private enum Layout {
        static let height: CGFloat = 40
        static let horizontalInset = Spacing.m
        static let imagePadding = Spacing.xs
        static let titleKern: CGFloat = 0.56
    }

    // MARK: - Properties

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            animatePress(isPressed: isHighlighted)
        }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        configuration = makeConfiguration()
        accessibilityLabel = String(localized: "Get PRO")
        heightAnchor.constraint(equalToConstant: Layout.height).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func makeConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.attributedTitle = AttributedString(
            "PRO",
            attributes: AttributeContainer([.font: Typography.semibold14, .kern: Layout.titleKern])
        )
        configuration.image = UIImage(resource: .sparkleIcon)
        configuration.imagePadding = Layout.imagePadding
        configuration.baseForegroundColor = Palette.textPrimary
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Layout.horizontalInset, bottom: 0, trailing: Layout.horizontalInset)
        configuration.background.customView = GradientView()
        configuration.cornerStyle = .capsule
        return configuration
    }
}

