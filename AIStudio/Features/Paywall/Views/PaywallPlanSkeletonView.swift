import UIKit

/// Заглушка размером с карточку плана, пока загружаются цены.
final class PaywallPlanSkeletonView: UIView {
    // MARK: - Types

    private enum Layout {
        /// Высота `PaywallPlanView` при стандартном размере текста, чтобы ничего не прыгало, когда придут цены.
        static let height: CGFloat = 72
        static let cornerRadius = Radius.l
        static let insets = NSDirectionalEdgeInsets(top: 20, leading: Spacing.xxl, bottom: 20, trailing: Spacing.l)
        static let titleSize = CGSize(width: 150, height: 14)
        static let priceSize = CGSize(width: 64, height: 12)
        static let barColor = Palette.accent.withAlphaComponent(0.08)
        static let borderColor = Palette.accent.withAlphaComponent(0.3)
        static let pulseOpacity: Float = 0.4
        static let pulseDuration: CFTimeInterval = 0.9
        static let pulseKey = "pulse"
    }

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

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Core Animation сбрасывает анимации, когда вид уходит из окна, поэтому перезапускаем при возврате.
        if window != nil {
            startPulse()
        }
    }

    // MARK: - Private

    private func setupViews() {
        isAccessibilityElement = true
        accessibilityLabel = String(localized: "Loading plans")
        layer.cornerRadius = Layout.cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Layout.borderColor.cgColor

        let titleBar = makeBar(size: Layout.titleSize)
        let priceBar = makeBar(size: Layout.priceSize)
        let stack = UIStackView(arrangedSubviews: [titleBar, priceBar])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = Spacing.s
        addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.height),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.insets.leading),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    private func makeBar(size: CGSize) -> UIView {
        let bar = UIView()
        bar.backgroundColor = Layout.barColor
        bar.layer.cornerRadius = size.height / 2
        bar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: size.width),
            bar.heightAnchor.constraint(equalToConstant: size.height),
        ])
        return bar
    }

    private func startPulse() {
        guard !UIAccessibility.isReduceMotionEnabled, layer.animation(forKey: Layout.pulseKey) == nil else { return }
        let pulse = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        pulse.fromValue = 1
        pulse.toValue = Layout.pulseOpacity
        pulse.duration = Layout.pulseDuration
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(pulse, forKey: Layout.pulseKey)
    }
}
