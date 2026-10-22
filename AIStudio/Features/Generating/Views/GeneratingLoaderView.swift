import UIKit

/// Розовое кольцо из макета: яркая дуга, за которой по часовой стрелке тянутся три тёмных сегмента.
/// С Reduce Motion кольцо пульсирует вместо вращения.
final class GeneratingLoaderView: UIView {
    // MARK: - Types

    private enum Layout {
        static let size: CGFloat = 200
        static let radius: CGFloat = 75
        static let lineWidth: CGFloat = 42
        /// Дуги в градусах по часовой стрелке от трёх часов, сняты с кадра лоадера в макете.
        /// Яркая дуга впереди; каждый тёмный сегмент прячется под скруглением предыдущего.
        static let segments: [(start: CGFloat, end: CGFloat, strength: CGFloat)] = [
            (-27, 6, 0.32),
            (6, 41, 0.56),
            (41, 75, 0.7),
            (75, 212, 1),
        ]
        static let rotationDuration: CFTimeInterval = 1.2
        static let pulseOpacity: Float = 0.5
        static let pulseDuration: CFTimeInterval = 0.9
        static let animationKey = "loading"
    }

    // MARK: - Properties

    private let ringLayer = CALayer()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override var intrinsicContentSize: CGSize {
        CGSize(width: Layout.size, height: Layout.size)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ringLayer.frame = bounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        for (layer, segment) in zip(ringLayer.sublayers ?? [], Layout.segments) {
            (layer as? CAShapeLayer)?.path = UIBezierPath(
                arcCenter: center,
                radius: Layout.radius,
                startAngle: segment.start * .pi / 180,
                endAngle: segment.end * .pi / 180,
                clockwise: true
            ).cgPath
        }
        CATransaction.commit()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Core Animation сбрасывает анимации, когда вид уходит из окна, поэтому перезапускаем при возврате.
        if window != nil {
            startAnimating()
        }
    }

    // MARK: - Private

    private func setupLayers() {
        layer.addSublayer(ringLayer)
        for segment in Layout.segments {
            let shape = CAShapeLayer()
            shape.fillColor = nil
            shape.lineWidth = Layout.lineWidth
            shape.lineCap = .round
            // Непрозрачные цвета не дают перекрывающимся скруглениям складываться в светлые серпы.
            shape.strokeColor = Self.blend(Palette.gradientEnd, over: Palette.background, strength: segment.strength).cgColor
            ringLayer.addSublayer(shape)
        }
    }

    private func startAnimating() {
        guard ringLayer.animation(forKey: Layout.animationKey) == nil else { return }
        let animation: CABasicAnimation
        if UIAccessibility.isReduceMotionEnabled {
            animation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
            animation.fromValue = 1
            animation.toValue = Layout.pulseOpacity
            animation.duration = Layout.pulseDuration
            animation.autoreverses = true
        } else {
            animation = CABasicAnimation(keyPath: "transform.rotation.z")
            animation.fromValue = 0
            animation.toValue = 2 * CGFloat.pi
            animation.duration = Layout.rotationDuration
        }
        animation.repeatCount = .infinity
        ringLayer.add(animation, forKey: Layout.animationKey)
    }

    private static func blend(_ color: UIColor, over background: UIColor, strength: CGFloat) -> UIColor {
        var (red, green, blue, alpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (backRed, backGreen, backBlue, backAlpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        background.getRed(&backRed, green: &backGreen, blue: &backBlue, alpha: &backAlpha)
        return UIColor(
            red: backRed + (red - backRed) * strength,
            green: backGreen + (green - backGreen) * strength,
            blue: backBlue + (blue - backBlue) * strength,
            alpha: 1
        )
    }
}
