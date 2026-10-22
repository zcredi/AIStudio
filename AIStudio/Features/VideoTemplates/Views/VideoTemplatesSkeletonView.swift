import UIKit

/// Заглушки чипов и карточек, пока загружается каталог.
final class VideoTemplatesSkeletonView: UIView {
    // MARK: - Types

    private enum Layout {
        static let chipSize = CGSize(width: 76, height: 33)
        static let chipCount = 4
        static let chipSpacing = Spacing.m
        static let cardHeight: CGFloat = 232
        static let rowCount = 3
        static let gridSpacing = Spacing.l
        static let sectionSpacing = Spacing.xxl
        static let blockColor = Palette.card.withAlphaComponent(0.6)
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
        accessibilityLabel = String(localized: "Loading templates")
        clipsToBounds = true

        let chips = UIStackView(arrangedSubviews: (0..<Layout.chipCount).map { _ in
            makeBlock(cornerRadius: Layout.chipSize.height / 2, size: Layout.chipSize)
        })
        chips.spacing = Layout.chipSpacing

        let rows = (0..<Layout.rowCount).map { _ in
            let row = UIStackView(arrangedSubviews: [makeCard(), makeCard()])
            row.spacing = Layout.gridSpacing
            row.distribution = .fillEqually
            return row
        }

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Layout.gridSpacing
        let chipsRow = UIStackView(arrangedSubviews: [chips, UIView()])
        ([chipsRow] + rows).forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(Layout.sectionSpacing, after: chipsRow)
        addSubview(contentStack)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.xxl),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.l),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.l),
        ])
    }

    private func makeCard() -> UIView {
        makeBlock(cornerRadius: Radius.l, size: CGSize(width: 0, height: Layout.cardHeight))
    }

    /// Нулевая ширина оставляет ширину на усмотрение стека.
    private func makeBlock(cornerRadius: CGFloat, size: CGSize) -> UIView {
        let block = UIView()
        block.backgroundColor = Layout.blockColor
        block.layer.cornerRadius = cornerRadius
        block.layer.cornerCurve = .continuous
        block.translatesAutoresizingMaskIntoConstraints = false
        block.heightAnchor.constraint(equalToConstant: size.height).isActive = true
        if size.width > 0 {
            block.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        }
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
