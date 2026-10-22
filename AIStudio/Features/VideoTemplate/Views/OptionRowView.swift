import UIKit

/// Параметр генерации, например Format или Quality, с текущим значением. Нажатие открывает варианты.
final class OptionRowView: UIControl {
    // MARK: - Types

    private enum Layout {
        static let height: CGFloat = 60
        static let insets = NSDirectionalEdgeInsets(top: Spacing.m, leading: Spacing.l, bottom: Spacing.m, trailing: Spacing.l)
        static let backgroundColor = Palette.card.withAlphaComponent(0.5)
        static let titleAlpha: CGFloat = 0.6
    }

    // MARK: - Properties

    var value: String? {
        get { valueLabel.text }
        set {
            valueLabel.text = newValue
            accessibilityValue = newValue
        }
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            animatePress(isPressed: isHighlighted)
        }
    }

    private let valueLabel = UILabel()

    // MARK: - Init

    init(title: String) {
        super.init(frame: .zero)
        setupViews(title: title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupViews(title: String) {
        backgroundColor = Layout.backgroundColor
        layer.cornerRadius = Radius.l
        layer.cornerCurve = .continuous

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typography.bold16
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary.withAlphaComponent(Layout.titleAlpha)

        valueLabel.font = Typography.bold16
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.textColor = Palette.textPrimary
        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.alignment = .center
        stack.spacing = Spacing.l
        stack.isUserInteractionEnabled = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = Layout.insets
        addSubview(stack)
        stack.pinEdges(to: self)
        heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.height).isActive = true

        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
    }
}
