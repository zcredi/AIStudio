import UIKit

/// Подпись «Cancel Anytime», кнопка покупки и юридические ссылки, прижатые к низу пейвола.
final class PaywallBottomBar: UIView {
    // MARK: - Types

    private enum Layout {
        static let captionInsets = NSDirectionalEdgeInsets(top: Spacing.s, leading: Spacing.l, bottom: Spacing.s, trailing: Spacing.l)
        static let captionIconSize: CGFloat = 24
        static let captionToButtonSpacing = Spacing.xxs
        static let legalInsets = NSDirectionalEdgeInsets(top: Spacing.l, leading: Spacing.l, bottom: Spacing.s, trailing: Spacing.l)
        static let legalSpacing = Spacing.m
        static let captionSymbol = "clock.arrow.trianglehead.counterclockwise.rotate.90"
        /// `captionSymbol` требует iOS 18.
        static let captionFallbackSymbol = "clock.arrow.circlepath"
    }

    // MARK: - Properties

    var onUnlock: (() -> Void)?
    var onRestore: (() -> Void)?
    var onPrivacyPolicy: (() -> Void)?
    var onTermsOfUse: (() -> Void)?

    private let unlockButton = PrimaryButton(title: String(localized: "Unlock now"))
    private let restoreButton = PaywallBottomBar.makeLegalButton(title: String(localized: "Restore Purchases"))
    private let privacyButton = PaywallBottomBar.makeLegalButton(title: String(localized: "Privacy Policy"))
    private let termsButton = PaywallBottomBar.makeLegalButton(title: String(localized: "Terms of Use"))

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.background
        setupActions()
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - API

    func render(isUnlockEnabled: Bool, isProcessing: Bool) {
        unlockButton.isEnabled = isUnlockEnabled && !isProcessing
        unlockButton.isLoading = isProcessing
        [restoreButton, privacyButton, termsButton].forEach { $0.isEnabled = !isProcessing }
    }

    // MARK: - Private

    private static func makeLegalButton(title: String) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = Palette.textSecondary
        configuration.contentInsets = .zero
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Typography.systemRegular11
            return attributes
        }
        return UIButton(configuration: configuration)
    }

    private func setupActions() {
        unlockButton.addAction(UIAction { [weak self] _ in self?.onUnlock?() }, for: .touchUpInside)
        restoreButton.addAction(UIAction { [weak self] _ in self?.onRestore?() }, for: .touchUpInside)
        privacyButton.addAction(UIAction { [weak self] _ in self?.onPrivacyPolicy?() }, for: .touchUpInside)
        termsButton.addAction(UIAction { [weak self] _ in self?.onTermsOfUse?() }, for: .touchUpInside)
    }

    private func setupViews() {
        let buttonContainer = UIView()
        buttonContainer.addSubview(unlockButton)
        unlockButton.pinEdges(to: buttonContainer, insets: NSDirectionalEdgeInsets(top: 0, leading: Spacing.l, bottom: 0, trailing: Spacing.l))

        let stack = UIStackView(arrangedSubviews: [makeCaption(), buttonContainer, makeLegalRow()])
        stack.axis = .vertical
        stack.setCustomSpacing(Layout.captionToButtonSpacing, after: stack.arrangedSubviews[0])
        addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    /// Только информация: подпись по задумке не нажимается.
    private func makeCaption() -> UIView {
        let symbolConfiguration = UIImage.SymbolConfiguration(font: Typography.systemRegular12)
        let symbol = UIImage(systemName: Layout.captionSymbol, withConfiguration: symbolConfiguration)
            ?? UIImage(systemName: Layout.captionFallbackSymbol, withConfiguration: symbolConfiguration)
        let iconView = UIImageView(image: symbol)
        iconView.tintColor = Palette.textSecondary
        iconView.contentMode = .center

        let label = UILabel()
        label.text = String(localized: "Cancel Anytime")
        label.font = Typography.systemRegular12
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Palette.textSecondary

        let row = UIStackView(arrangedSubviews: [iconView, label])
        row.alignment = .center
        row.isAccessibilityElement = true
        row.accessibilityLabel = label.text

        let container = UIView()
        container.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Layout.captionIconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.captionIconSize),
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: Layout.captionInsets.top),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Layout.captionInsets.bottom),
            row.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        ])
        return container
    }

    private func makeLegalRow() -> UIView {
        privacyButton.contentHorizontalAlignment = .leading
        termsButton.contentHorizontalAlignment = .trailing

        let row = UIStackView(arrangedSubviews: [privacyButton, restoreButton, termsButton])
        row.spacing = Layout.legalSpacing
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = Layout.legalInsets
        // Боковые ссылки делят оставшуюся ширину, чтобы «Restore Purchases» оставалась по центру.
        privacyButton.widthAnchor.constraint(equalTo: termsButton.widthAnchor).isActive = true
        restoreButton.setContentHuggingPriority(.required, for: .horizontal)
        restoreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        return row
    }
}
