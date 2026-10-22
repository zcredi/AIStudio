import UIKit

/// Заглушки карточек чатов, пока грузится история.
final class HistorySkeletonView: UIView {
    // MARK: - Types

    private enum Layout {
        static let insets = NSDirectionalEdgeInsets(top: Spacing.xxl, leading: Spacing.l, bottom: 0, trailing: Spacing.l)
        static let titleSize = CGSize(width: 96, height: 20)
        static let rowHeight: CGFloat = 72
        static let rowCount = 4
        static let rowSpacing = Spacing.m
        static let cardColor = Palette.card.withAlphaComponent(0.4)
        static let pulseOpacity: Float = 0.4
        static let pulseDuration: CFTimeInterval = 0.9
        static let pulseKey = "pulse"
    }

    // MARK: - Properties

    /// Пульсация идёт на содержимом, а не на самом виде, поэтому затухание вида его всё равно скрывает.
    private let contentStack = UIStackView()

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
        accessibilityLabel = String(localized: "Loading chats")

        let title = makeBlock()
        let rows = (0..<Layout.rowCount).map { _ in makeBlock() }
        let stack = contentStack
        ([title] + rows).forEach(stack.addArrangedSubview)
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = Layout.rowSpacing
        stack.setCustomSpacing(Spacing.l, after: title)
        addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.insets.top),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.insets.leading),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.insets.trailing),
            title.widthAnchor.constraint(equalToConstant: Layout.titleSize.width),
            title.heightAnchor.constraint(equalToConstant: Layout.titleSize.height),
        ] + rows.flatMap {
            [$0.widthAnchor.constraint(equalTo: stack.widthAnchor), $0.heightAnchor.constraint(equalToConstant: Layout.rowHeight)]
        })
    }

    private func makeBlock() -> UIView {
        let block = UIView()
        block.backgroundColor = Layout.cardColor
        block.layer.cornerRadius = Radius.l
        block.layer.cornerCurve = .continuous
        block.translatesAutoresizingMaskIntoConstraints = false
        return block
    }

    private func startPulse() {
        guard !UIAccessibility.isReduceMotionEnabled, contentStack.layer.animation(forKey: Layout.pulseKey) == nil else { return }
        let pulse = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        pulse.fromValue = 1
        pulse.toValue = Layout.pulseOpacity
        pulse.duration = Layout.pulseDuration
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        contentStack.layer.add(pulse, forKey: Layout.pulseKey)
    }
}
