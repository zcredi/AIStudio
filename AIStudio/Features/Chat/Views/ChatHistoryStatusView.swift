import UIKit

/// Закрывает переписку, пока загружается существующий чат: заглушки пузырей или ошибка с повтором.
final class ChatHistoryStatusView: UIView {
    // MARK: - Types

    private enum Layout {
        static let sideInset = Spacing.l
        static let topInset = Spacing.xxl
        static let spacing = Spacing.xxl
        static let userBubbleSize = CGSize(width: 220, height: 56)
        static let replyBubbleSize = CGSize(width: 280, height: 140)
        static let placeholderColor = Palette.card.withAlphaComponent(0.5)
        static let messageColor = Palette.textPrimary.withAlphaComponent(0.6)
        static let pulseOpacity: Float = 0.4
        static let pulseDuration: CFTimeInterval = 0.9
        static let pulseKey = "pulse"
    }

    // MARK: - Properties

    var onRetry: (() -> Void)?

    private let placeholders = UIView()
    private let errorStack = UIStackView()
    private let errorLabel = UILabel()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlaceholders()
        setupError()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - API

    func render(_ history: Loadable<[ChatMessage]>) {
        switch history {
        case .loading:
            placeholders.isHidden = false
            errorStack.isHidden = true
            startPulse()
        case .failed(let error):
            errorLabel.text = error.message
            placeholders.isHidden = true
            errorStack.isHidden = false
        case .loaded:
            placeholders.isHidden = true
            errorStack.isHidden = true
        }
    }

    // MARK: - Private

    private func setupPlaceholders() {
        isAccessibilityElement = false
        let userBubble = makePlaceholder(maskedCorners: [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner])
        let replyBubble = makePlaceholder(maskedCorners: [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner])
        placeholders.accessibilityLabel = String(localized: "Loading messages")
        placeholders.isAccessibilityElement = true
        addSubview(placeholders)
        [placeholders, userBubble, replyBubble].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            if $0 !== placeholders { placeholders.addSubview($0) }
        }
        placeholders.pinEdges(to: self)
        NSLayoutConstraint.activate([
            userBubble.topAnchor.constraint(equalTo: placeholders.topAnchor, constant: Layout.topInset),
            userBubble.trailingAnchor.constraint(equalTo: placeholders.trailingAnchor, constant: -Layout.sideInset),
            userBubble.widthAnchor.constraint(equalToConstant: Layout.userBubbleSize.width),
            userBubble.heightAnchor.constraint(equalToConstant: Layout.userBubbleSize.height),
            replyBubble.topAnchor.constraint(equalTo: userBubble.bottomAnchor, constant: Layout.spacing),
            replyBubble.leadingAnchor.constraint(equalTo: placeholders.leadingAnchor, constant: Layout.sideInset),
            replyBubble.widthAnchor.constraint(equalToConstant: Layout.replyBubbleSize.width),
            replyBubble.heightAnchor.constraint(equalToConstant: Layout.replyBubbleSize.height),
        ])
    }

    private func makePlaceholder(maskedCorners: CACornerMask) -> UIView {
        let view = UIView()
        view.backgroundColor = Layout.placeholderColor
        view.layer.cornerRadius = Radius.l
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = maskedCorners
        return view
    }

    private func setupError() {
        errorLabel.font = Typography.regular14
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.textColor = Layout.messageColor
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0

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

        errorStack.axis = .vertical
        errorStack.alignment = .center
        errorStack.spacing = Spacing.s
        errorStack.addArrangedSubview(errorLabel)
        errorStack.addArrangedSubview(retryButton)
        errorStack.isHidden = true
        addSubview(errorStack)
        errorStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            errorStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.topInset),
            errorStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.topInset),
        ])
    }

    private func startPulse() {
        guard !UIAccessibility.isReduceMotionEnabled, placeholders.layer.animation(forKey: Layout.pulseKey) == nil else { return }
        let pulse = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        pulse.fromValue = 1
        pulse.toValue = Layout.pulseOpacity
        pulse.duration = Layout.pulseDuration
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        placeholders.layer.add(pulse, forKey: Layout.pulseKey)
    }
}
