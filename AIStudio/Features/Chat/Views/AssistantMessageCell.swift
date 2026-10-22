import UIKit

/// Ответ ассистента, отрисованный из Markdown, с кнопками Copy и, на последнем ответе, Regenerate.
final class AssistantMessageCell: UICollectionViewCell {
    // MARK: - Types

    private enum Layout {
        static let leadingInset = Spacing.l
        /// Справа у ответа отступ больше, чем у пузыря пользователя слева.
        static let minimumTrailingInset: CGFloat = 40
        static let insets = NSDirectionalEdgeInsets(top: Spacing.l, leading: Spacing.l, bottom: Spacing.s, trailing: Spacing.s)
        /// Справа у текста больше места, чем у разделителя и строки с действиями.
        static let textInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: Spacing.s)
        static let sectionSpacing = Spacing.l
        static let separatorColor = UIColor(white: 0.85, alpha: 0.1)
        static let actionsAlpha: CGFloat = 0.5
        static let actionSize: CGFloat = 40
    }

    // MARK: - Properties

    var onCopy: (() -> Void)?
    var onRegenerate: (() -> Void)?

    private let bubble = AssistantBubbleView()
    private let messageLabel = UILabel()
    private let regenerateButton = AssistantMessageCell.makeActionButton(image: UIImage(resource: .regenerateIcon), label: String(localized: "Regenerate"))
    private let copyButton = AssistantMessageCell.makeActionButton(image: UIImage(resource: .copyIcon), label: String(localized: "Copy"))

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
        onCopy = nil
        onRegenerate = nil
    }

    // MARK: - API

    func configure(with text: NSAttributedString, canRegenerate: Bool) {
        messageLabel.attributedText = text
        regenerateButton.isHidden = !canRegenerate
    }

    // MARK: - Private

    private static func makeActionButton(image: UIImage, label: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.tintColor = Palette.textPrimary
        button.alpha = Layout.actionsAlpha
        button.accessibilityLabel = label
        return button
    }

    private func setupViews() {
        messageLabel.numberOfLines = 0
        messageLabel.adjustsFontForContentSizeCategory = true

        let separator = UIView()
        separator.backgroundColor = Layout.separatorColor

        copyButton.addAction(UIAction { [weak self] _ in self?.onCopy?() }, for: .touchUpInside)
        regenerateButton.addAction(UIAction { [weak self] _ in self?.onRegenerate?() }, for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [copyButton, UIView(), regenerateButton])
        // Области нажатия по 40 pt; сдвиг строки оставляет иконки 24 pt там, где они в макете.
        actions.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: -Spacing.s, bottom: 0, trailing: 0)
        actions.isLayoutMarginsRelativeArrangement = true

        let messageContainer = UIView()
        messageContainer.addSubview(messageLabel)
        messageLabel.pinEdges(to: messageContainer, insets: Layout.textInsets)

        let stack = UIStackView(arrangedSubviews: [messageContainer, separator, actions])
        stack.axis = .vertical
        stack.spacing = Layout.sectionSpacing
        stack.setCustomSpacing(Spacing.s, after: separator)

        contentView.addSubview(bubble)
        bubble.addSubview(stack)
        [bubble, stack, separator, copyButton, regenerateButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        let insets = Layout.insets
        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.leadingInset),
            bubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -Layout.minimumTrailingInset),

            stack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: insets.top),
            stack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -insets.bottom),
            stack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: insets.leading),
            stack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -insets.trailing),

            separator.heightAnchor.constraint(equalToConstant: 1),
            copyButton.widthAnchor.constraint(equalToConstant: Layout.actionSize),
            copyButton.heightAnchor.constraint(equalToConstant: Layout.actionSize),
            regenerateButton.widthAnchor.constraint(equalToConstant: Layout.actionSize),
            regenerateButton.heightAnchor.constraint(equalToConstant: Layout.actionSize),
        ])
    }
}
