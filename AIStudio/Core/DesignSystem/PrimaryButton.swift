import UIKit

/// Главная кнопка на всю ширину на фирменном градиенте, например «Unlock now» или «Continue».
final class PrimaryButton: UIButton {
    // MARK: - Types

    private enum Layout {
        static let minimumHeight: CGFloat = 50
        static let cornerRadius = Radius.l
        static let disabledBackground = Palette.card.withAlphaComponent(0.4)
        static let disabledForeground = Palette.textPrimary.withAlphaComponent(0.12)
    }

    // MARK: - Properties

    /// Пока действие выполняется, вместо заголовка показывается спиннер.
    var isLoading = false {
        didSet {
            guard isLoading != oldValue else { return }
            setNeedsUpdateConfiguration()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            animatePress(isPressed: isHighlighted)
        }
    }

    private let title: String
    private let gradientView = GradientView()

    // MARK: - Init

    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        configuration = makeConfiguration()
        heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.minimumHeight).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func updateConfiguration() {
        guard var configuration else { return }
        configuration.title = isLoading ? nil : title
        configuration.showsActivityIndicator = isLoading
        // Кнопка, занятая своим действием, сохраняет градиент, чтобы спиннер было видно.
        let looksEnabled = isEnabled || isLoading
        configuration.baseForegroundColor = looksEnabled ? Palette.textPrimary : Layout.disabledForeground
        self.configuration = configuration
        setGradientVisible(looksEnabled)
    }

    // MARK: - Private

    /// Градиент всегда лежит в фоне и плавно гаснет над тёмной плашкой неактивной кнопки.
    /// Сам фон конфигурации не меняем: UIKit падает, если перестраивать его во время анимации.
    private func setGradientVisible(_ isVisible: Bool) {
        let alpha: CGFloat = isVisible ? 1 : 0
        guard gradientView.alpha != alpha else { return }
        guard window != nil else {
            gradientView.alpha = alpha
            return
        }
        UIView.animate(withDuration: Motion.fast, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.gradientView.alpha = alpha
        }
    }

    private func makeConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = Palette.textPrimary
        configuration.background.customView = gradientView
        configuration.background.backgroundColor = Layout.disabledBackground
        configuration.background.cornerRadius = Layout.cornerRadius
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Typography.semibold16
            return attributes
        }
        return configuration
    }
}
