import UIKit

/// Выглядит как поле ввода чата; по нажатию открывает чат с поднятой клавиатурой.
final class PromptFieldButton: UIControl {
    // MARK: - Types

    private enum Layout {
        static let cornerRadius = Radius.l
        static let insets = NSDirectionalEdgeInsets(top: Spacing.l, leading: Spacing.l, bottom: Spacing.l, trailing: Spacing.l)
        static let iconSize: CGFloat = 24
        static let placeholderColor = Palette.textPrimary.withAlphaComponent(0.5)
        /// В Figma граница 2 pt нарисована только сверху и снизу; маска растворяет её по бокам.
        /// Прозрачность подобрана так, как граница читается поверх размытого поля в макете.
        static let borderWidth: CGFloat = 2
        static let borderColor = Palette.gradientStart.withAlphaComponent(0.4)
        static let borderMaskLocations: [NSNumber] = [0, 0.2, 0.8, 1]
    }

    // MARK: - Properties

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            animatePress(isPressed: isHighlighted)
        }
    }

    private let glassView = GlassView(material: .regular, shape: .roundedRect(cornerRadius: Layout.cornerRadius))
    private let borderLayer = CAShapeLayer()
    private let borderMask = CAGradientLayer()

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

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = Layout.borderWidth / 2
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        borderLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: inset, dy: inset),
            cornerRadius: Layout.cornerRadius - inset
        ).cgPath
        borderLayer.frame = bounds
        borderMask.frame = bounds
        CATransaction.commit()
    }

    // MARK: - Private

    private func setupViews() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = String(localized: "Ask anything")
        accessibilityHint = String(localized: "Opens the chat")

        let iconView = UIImageView(image: UIImage(resource: .generateBMonoIcon))
        iconView.tintColor = Palette.textPrimary

        let placeholderLabel = UILabel()
        placeholderLabel.text = String(localized: "Ask anything...")
        placeholderLabel.font = Typography.regular16
        placeholderLabel.adjustsFontForContentSizeCategory = true
        placeholderLabel.textColor = Layout.placeholderColor

        let row = UIStackView(arrangedSubviews: [iconView, placeholderLabel])
        row.alignment = .center
        row.spacing = Spacing.l
        row.isUserInteractionEnabled = false

        glassView.isUserInteractionEnabled = false
        addSubview(glassView)
        glassView.pinEdges(to: self)
        glassView.contentView.addSubview(row)
        row.pinEdges(to: glassView.contentView, insets: Layout.insets)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),
        ])

        borderLayer.fillColor = nil
        borderLayer.strokeColor = Layout.borderColor.cgColor
        borderLayer.lineWidth = Layout.borderWidth
        borderMask.colors = [UIColor.black, .clear, .clear, .black].map(\.cgColor)
        borderMask.locations = Layout.borderMaskLocations
        borderLayer.mask = borderMask
        layer.addSublayer(borderLayer)
    }
}
