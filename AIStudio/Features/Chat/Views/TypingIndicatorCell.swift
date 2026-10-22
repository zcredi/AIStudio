import UIKit

/// Три точки в пузыре ассистента, пока генерируется ответ.
final class TypingIndicatorCell: UICollectionViewCell {
    // MARK: - Types

    private enum Layout {
        static let leadingInset = Spacing.l
        static let insets = NSDirectionalEdgeInsets(top: Spacing.l, leading: Spacing.l, bottom: Spacing.l, trailing: Spacing.l)
        static let dotSpacing = Spacing.xs
        /// Первая точка самая крупная; остальные уменьшаются, как шлейф.
        static let dotSizes: [CGFloat] = [18, 14, 10]
        static let dotColor = Palette.accent.withAlphaComponent(0.15)
        static let pulseScale: CGFloat = 0.7
        static let pulseDuration: CFTimeInterval = 0.6
        static let pulseStagger: CFTimeInterval = 0.15
        static let pulseKey = "pulse"
    }

    // MARK: - Properties

    private var dots: [UIView] = []

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
        // Core Animation сбрасывает анимации, когда ячейка уходит из окна, поэтому перезапускаем при возврате.
        if window != nil {
            startPulse()
        }
    }

    // MARK: - Private

    private func setupViews() {
        isAccessibilityElement = true
        accessibilityLabel = String(localized: "AI is typing")

        let bubble = AssistantBubbleView()
        dots = Layout.dotSizes.enumerated().map { index, size in
            index == 0 ? makeLeadingDot(size: size) : makeDot(size: size)
        }
        let row = UIStackView(arrangedSubviews: dots)
        row.alignment = .center
        row.spacing = Layout.dotSpacing

        contentView.addSubview(bubble)
        bubble.addSubview(row)
        [bubble, row].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        let insets = Layout.insets
        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.leadingInset),
            row.topAnchor.constraint(equalTo: bubble.topAnchor, constant: insets.top),
            row.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -insets.bottom),
            row.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: insets.leading),
            row.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -insets.trailing),
        ])
    }

    private func makeLeadingDot(size: CGFloat) -> UIView {
        let dot = GradientView()
        styleDot(dot, size: size)
        return dot
    }

    private func makeDot(size: CGFloat) -> UIView {
        let dot = UIView()
        dot.backgroundColor = Layout.dotColor
        styleDot(dot, size: size)
        return dot
    }

    private func styleDot(_ dot: UIView, size: CGFloat) {
        dot.layer.cornerRadius = size / 2
        dot.clipsToBounds = true
        dot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: size),
            dot.heightAnchor.constraint(equalToConstant: size),
        ])
    }

    /// Мягкая волна по точкам; с Reduce Motion они стоят на месте.
    private func startPulse() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let now = CACurrentMediaTime()
        for (index, dot) in dots.enumerated() where dot.layer.animation(forKey: Layout.pulseKey) == nil {
            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 1
            pulse.toValue = Layout.pulseScale
            pulse.duration = Layout.pulseDuration
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.beginTime = now + Double(index) * Layout.pulseStagger
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            dot.layer.add(pulse, forKey: Layout.pulseKey)
        }
    }
}
