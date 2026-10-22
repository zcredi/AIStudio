import UIKit

/// Показывается вместо ответа, который не удалось получить, с кнопкой повтора.
final class ChatFailureCell: UICollectionViewCell {
    // MARK: - Types

    private enum Layout {
        static let insets = NSDirectionalEdgeInsets(top: 0, leading: Spacing.xxl, bottom: 0, trailing: Spacing.xxl)
        static let messageColor = Palette.textPrimary.withAlphaComponent(0.6)
    }

    // MARK: - Properties

    var onRetry: (() -> Void)?

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

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        onRetry = nil
    }

    // MARK: - API

    func configure(with error: UserFacingError) {
        messageLabel.text = error.message
    }

    // MARK: - Private

    private func setupViews() {
        messageLabel.font = Typography.regular14
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = Layout.messageColor
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var configuration = UIButton.Configuration.plain()
        configuration.title = String(localized: "Try again")
        configuration.baseForegroundColor = Palette.textPrimary
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Typography.semibold14
            return attributes
        }
        let retryButton = UIButton(configuration: configuration)
        retryButton.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [messageLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Spacing.xs
        contentView.addSubview(stack)
        stack.pinEdges(to: contentView, insets: Layout.insets)
    }
}
