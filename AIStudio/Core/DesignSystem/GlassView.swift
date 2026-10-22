import UIKit

/// Поверхность для контролов, парящих над контентом. Сабвью добавлять в `contentView`.
final class GlassView: UIView {
    // MARK: - Types

    enum Shape: Equatable {
        case rectangle
        case roundedRect(cornerRadius: CGFloat)
        case capsule
    }

    // MARK: - Properties

    var contentView: UIView {
        effectView.contentView
    }

    var shape: Shape {
        didSet {
            guard shape != oldValue else { return }
            applyShape()
        }
    }

    private let material: GlassMaterial
    private let effectView: UIVisualEffectView

    // MARK: - Init

    init(material: GlassMaterial = .regular, shape: Shape = .rectangle) {
        self.material = material
        self.shape = shape
        effectView = UIVisualEffectView(effect: material.makeEffect())
        super.init(frame: .zero)
        setupViews()
        applyShape()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        // Стекло на iOS 26 само следит за скруглением капсулы; фолбэку с блюром нужна текущая высота.
        if shape == .capsule, !isLiquidGlassAvailable {
            effectView.layer.cornerRadius = bounds.height / 2
        }
    }

    // MARK: - Private

    private var isLiquidGlassAvailable: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }

    private func setupViews() {
        if !isLiquidGlassAvailable {
            effectView.contentView.backgroundColor = material.fallbackTintColor
        }
        addSubview(effectView)
        effectView.pinEdges(to: self)
    }

    private func applyShape() {
        if #available(iOS 26.0, *) {
            effectView.cornerConfiguration = shape.cornerConfiguration
        } else {
            effectView.clipsToBounds = shape != .rectangle
            effectView.layer.cornerCurve = .continuous
            effectView.layer.cornerRadius = shape.fixedCornerRadius
            setNeedsLayout()
        }
    }
}

// MARK: - Shape

private extension GlassView.Shape {
    @available(iOS 26.0, *)
    var cornerConfiguration: UICornerConfiguration {
        switch self {
        case .rectangle:
            .corners(radius: .fixed(0))
        case .roundedRect(let cornerRadius):
            .corners(radius: .fixed(cornerRadius))
        case .capsule:
            .capsule()
        }
    }

    /// Радиус для фолбэка с блюром; у капсул он считается от высоты при раскладке.
    var fixedCornerRadius: CGFloat {
        switch self {
        case .rectangle, .capsule:
            0
        case .roundedRect(let cornerRadius):
            cornerRadius
        }
    }
}
