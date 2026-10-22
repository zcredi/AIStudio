import UIKit

/// Поле сообщения растёт до трёх строк, дальше прокручивается; кнопка отправки прижата справа.
final class ChatInputBar: UIView {
    // MARK: - Types

    private enum Layout {
        static let cornerRadius = Radius.l
        static let insets = NSDirectionalEdgeInsets(top: Spacing.xxl, leading: Spacing.l, bottom: Spacing.xxl, trailing: Spacing.l)
        static let sendButtonSize: CGFloat = 40
        static let textToButtonSpacing = Spacing.m
        static let maximumLineCount: CGFloat = 3
        static let disabledSendAlpha: CGFloat = 0.3
    }

    // MARK: - Properties

    var onTextChange: ((String) -> Void)?
    var onSend: (() -> Void)?

    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let sendButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(resource: .sendIcon)
        configuration.baseForegroundColor = Palette.textPrimary
        configuration.background.customView = GradientView()
        configuration.cornerStyle = .capsule
        configuration.contentInsets = .zero
        return UIButton(configuration: configuration)
    }()
    private lazy var textHeight = textView.heightAnchor.constraint(equalToConstant: Layout.sendButtonSize)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTextHeight()
    }

    // MARK: - API

    /// Не трогает текст, если он уже совпадает, чтобы курсор не прыгал при наборе.
    func render(text: String, placeholder: String, canSend: Bool) {
        if textView.text != text {
            textView.text = text
            updateTextHeight()
        }
        placeholderLabel.text = placeholder
        placeholderLabel.isHidden = !text.isEmpty
        sendButton.isEnabled = canSend
        let sendAlpha = canSend ? 1 : Layout.disabledSendAlpha
        guard sendButton.alpha != sendAlpha else { return }
        UIView.animate(withDuration: Motion.fast, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            self.sendButton.alpha = sendAlpha
        }
    }

    func focus() {
        textView.becomeFirstResponder()
    }

    // MARK: - Private

    private func setupViews() {
        backgroundColor = Palette.card
        layer.cornerRadius = Layout.cornerRadius
        layer.cornerCurve = .continuous
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        textView.backgroundColor = .clear
        textView.font = Typography.regular16
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = Palette.textPrimary
        textView.tintColor = Palette.textPrimary
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.accessibilityLabel = String(localized: "Message")

        placeholderLabel.font = Typography.regular16
        placeholderLabel.adjustsFontForContentSizeCategory = true
        placeholderLabel.textColor = Palette.textSecondary
        placeholderLabel.isAccessibilityElement = false

        sendButton.accessibilityLabel = String(localized: "Send")
        sendButton.addAction(UIAction { [weak self] _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self?.onSend?()
        }, for: .touchUpInside)

        [textView, placeholderLabel, sendButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    }

    private func setupLayout() {
        let insets = Layout.insets
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading),
            textView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -Layout.textToButtonSpacing),
            textHeight,

            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),

            // Кнопка остаётся внизу справа, пока поле растёт над ней.
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.trailing),
            sendButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: Layout.sendButtonSize),
            sendButton.heightAnchor.constraint(equalToConstant: Layout.sendButtonSize),
        ])
    }

    /// Подгоняет высоту поля под текст: от одной строки (высотой с кнопку) до трёх.
    private func updateTextHeight() {
        guard let font = textView.font, textView.bounds.width > 0 else { return }
        let oneLineInset = max((Layout.sendButtonSize - font.lineHeight) / 2, 0)
        let maximumHeight = font.lineHeight * Layout.maximumLineCount + oneLineInset * 2
        textView.textContainerInset = UIEdgeInsets(top: oneLineInset, left: 0, bottom: oneLineInset, right: 0)

        let fittingHeight = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)).height
        let height = min(max(fittingHeight, Layout.sendButtonSize), maximumHeight)
        textView.isScrollEnabled = fittingHeight > maximumHeight
        guard textHeight.constant != height else { return }
        textHeight.constant = height
    }
}

// MARK: - UITextViewDelegate

extension ChatInputBar: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateTextHeight()
        onTextChange?(textView.text)
    }
}
