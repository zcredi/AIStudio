import UIKit

/// Сообщение пользователя: градиентный пузырь справа с острым нижним правым углом.
final class UserMessageCell: UICollectionViewCell {
    // MARK: - Types

    private enum Layout {
        static let sideInset = Spacing.l
        static let bubbleInsets = NSDirectionalEdgeInsets(top: Spacing.l, leading: Spacing.l, bottom: Spacing.l, trailing: Spacing.l)
        static let cornerRadius = Radius.l
        static let gradientAlpha: CGFloat = 0.9
    }

    // MARK: - Properties

    private let bubble = GradientView()
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

    // MARK: - API

    func configure(with message: ChatMessage) {
        messageLabel.text = message.text
        accessibilityLabel = String(localized: "You: \(message.text)")
    }

    // MARK: - Private

    private func setupViews() {
        isAccessibilityElement = true
        bubble.alpha = Layout.gradientAlpha
        bubble.layer.cornerRadius = Layout.cornerRadius
        bubble.layer.cornerCurve = .continuous
        bubble.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        bubble.clipsToBounds = true

        messageLabel.font = Typography.regular16
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = Palette.textPrimary
        messageLabel.numberOfLines = 0

        // Текст лежит вне полупрозрачного градиента, поэтому остаётся полностью непрозрачным.
        contentView.addSubview(bubble)
        contentView.addSubview(messageLabel)
        [bubble, messageLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        let insets = Layout.bubbleInsets
        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.sideInset),
            bubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: Layout.sideInset),

            messageLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: insets.top),
            messageLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -insets.bottom),
            messageLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: insets.leading),
            messageLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -insets.trailing),
        ])
    }
}
