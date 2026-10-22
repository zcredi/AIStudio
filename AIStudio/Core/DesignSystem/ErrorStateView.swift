import UIKit

/// Сообщение об ошибке по центру и кнопка «Try again» для контента, который не загрузился.
final class ErrorStateView: UIView {
    // MARK: - Types

    private enum Layout {
        static let sideInset = Spacing.xxl
        static let messageColor = Palette.textPrimary.withAlphaComponent(0.6)
    }

    // MARK: - Properties

    var onRetry: (() -> Void)?

    var message: String? {
        get { messageLabel.text }
        set { messageLabel.text = newValue }
    }

    private let messageLabel = UILabel()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupViews() {
        messageLabel.font = Typography.regular16
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = Layout.messageColor
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var configuration = UIButton.Configuration.plain()
        configuration.title = String(localized: "Try again")
        configuration.baseForegroundColor = Palette.textPrimary
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Typography.semibold16
            return attributes
        }
        let retryButton = UIButton(configuration: configuration)
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [messageLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Spacing.s
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.sideInset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.sideInset),
        ])
    }
}
