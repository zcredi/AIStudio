import UIKit

/// Фирменный градиент из Figma, слева направо.
final class GradientView: UIView {
    // MARK: - Properties

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        gradientLayer.colors = [Palette.gradientStart.cgColor, Palette.gradientEnd.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
