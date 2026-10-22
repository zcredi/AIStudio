import UIKit

/// Стеклянная капсула с иконкой статуса и коротким сообщением, например «Copied».
final class ToastView: UIView {
    // MARK: - Types

    enum Style {
        case success
        case failure
    }

    private enum Layout {
        static let insets = NSDirectionalEdgeInsets(top: Spacing.m, leading: Spacing.l, bottom: Spacing.m, trailing: Spacing.xl)
        static let iconSize: CGFloat = 22
        static let borderColor = Palette.accent.withAlphaComponent(0.12)
        static let dismissDragDistance: CGFloat = -12
    }

    // MARK: - Properties

    /// Вызывается, когда пользователь смахивает тост вверх.
    var onSwipeUp: (() -> Void)?

    // MARK: - Init

    init(style: Style, message: String) {
        super.init(frame: .zero)
        setupViews(style: style, message: message)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    // MARK: - Private

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard recognizer.state == .changed, recognizer.translation(in: self).y < Layout.dismissDragDistance else { return }
        recognizer.isEnabled = false
        onSwipeUp?()
    }

    private func setupViews(style: Style, message: String) {
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        isAccessibilityElement = true
        accessibilityLabel = message
        layer.borderWidth = 1
        layer.borderColor = Layout.borderColor.cgColor
        layer.cornerCurve = .continuous

        let glassView = GlassView(material: .regular, shape: .capsule)
        addSubview(glassView)
        glassView.pinEdges(to: self)

        let iconView = UIImageView(image: UIImage(
            systemName: style.symbolName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        ))
        iconView.tintColor = style.tintColor
        iconView.contentMode = .center

        let label = UILabel()
        label.text = message
        label.font = Typography.medium16
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Palette.textPrimary

        let row = UIStackView(arrangedSubviews: [iconView, label])
        row.alignment = .center
        row.spacing = Spacing.m
        glassView.contentView.addSubview(row)
        row.pinEdges(to: glassView.contentView, insets: Layout.insets)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),
        ])
    }
}

// MARK: - Style

private extension ToastView.Style {
    var symbolName: String {
        switch self {
        case .success:
            "checkmark"
        case .failure:
            "xmark"
        }
    }

    var tintColor: UIColor {
        switch self {
        case .success:
            Palette.accentGreen
        case .failure:
            Palette.accentRed
        }
    }
}
