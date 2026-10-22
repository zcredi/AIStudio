import UIKit

/// Карточка варианта покупки. Выбранная карточка получает градиентную рамку из макета.
final class PaywallPlanView: UIControl {
    // MARK: - Types

    private enum Layout {
        static let cornerRadius = Radius.l
        static let insets = NSDirectionalEdgeInsets(top: Spacing.l, leading: Spacing.xxl, bottom: Spacing.l, trailing: Spacing.l)
        static let textSpacing = Spacing.xs
        static let borderWidth: CGFloat = 1
        static let idleBorderColor = Palette.accent.withAlphaComponent(0.3)
    }

    // MARK: - Properties

    let planID: PaywallPlan.ID

    override var isSelected: Bool {
        didSet {
            guard isSelected != oldValue else { return }
            updateSelection(animated: true)
        }
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            animatePress(isPressed: isHighlighted)
        }
    }

    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let badgeView = PaywallSavingsBadgeView()
    private let idleBorderLayer = CAShapeLayer()
    private let selectedBorderLayer = CAGradientLayer()
    private let selectedBorderMask = CAShapeLayer()

    // MARK: - Init

    init(plan: PaywallPlan) {
        planID = plan.id
        super.init(frame: .zero)
        setupLayers()
        setupViews()
        configure(with: plan)
        updateSelection(animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = Layout.borderWidth / 2
        let path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: inset, dy: inset),
            cornerRadius: Layout.cornerRadius
        ).cgPath

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        idleBorderLayer.path = path
        selectedBorderMask.path = path
        selectedBorderLayer.frame = bounds
        CATransaction.commit()
    }

    // MARK: - API

    func configure(with plan: PaywallPlan) {
        titleLabel.attributedText = Self.title(for: plan)
        priceLabel.text = plan.fullPrice
        badgeView.text = plan.savings
        badgeView.isHidden = plan.savings == nil
        accessibilityLabel = [plan.title, String(localized: "per week"), plan.fullPrice, plan.savings]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    // MARK: - Private

    private static func title(for plan: PaywallPlan) -> NSAttributedString {
        let title = NSMutableAttributedString(
            string: plan.title,
            attributes: [.font: Typography.medium16, .foregroundColor: Palette.textPrimary]
        )
        title.append(NSAttributedString(
            string: " " + String(localized: "/ week"),
            attributes: [.font: Typography.regular16, .foregroundColor: Palette.textPrimary]
        ))
        return title
    }

    private func setupLayers() {
        idleBorderLayer.fillColor = nil
        idleBorderLayer.strokeColor = Layout.idleBorderColor.cgColor
        idleBorderLayer.lineWidth = Layout.borderWidth

        selectedBorderMask.fillColor = nil
        selectedBorderMask.strokeColor = UIColor.black.cgColor
        selectedBorderMask.lineWidth = Layout.borderWidth
        selectedBorderLayer.colors = [Palette.gradientStart.cgColor, Palette.gradientEnd.cgColor]
        selectedBorderLayer.startPoint = CGPoint(x: 0, y: 0.5)
        selectedBorderLayer.endPoint = CGPoint(x: 1, y: 0.5)
        selectedBorderLayer.mask = selectedBorderMask

        layer.addSublayer(idleBorderLayer)
        layer.addSublayer(selectedBorderLayer)
    }

    private func setupViews() {
        isAccessibilityElement = true
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        priceLabel.font = Typography.regular14
        priceLabel.adjustsFontForContentSizeCategory = true
        priceLabel.textColor = Palette.textSecondary

        let textStack = UIStackView(arrangedSubviews: [titleLabel, priceLabel])
        textStack.axis = .vertical
        textStack.spacing = Layout.textSpacing

        let contentStack = UIStackView(arrangedSubviews: [textStack, badgeView])
        contentStack.alignment = .top
        contentStack.spacing = Spacing.s
        contentStack.isUserInteractionEnabled = false
        addSubview(contentStack)
        contentStack.pinEdges(to: self, insets: Layout.insets)
    }

    private func updateSelection(animated: Bool) {
        accessibilityTraits = isSelected ? [.button, .selected] : .button
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        CATransaction.setAnimationDuration(Motion.fast)
        idleBorderLayer.opacity = isSelected ? 0 : 1
        selectedBorderLayer.opacity = isSelected ? 1 : 0
        CATransaction.commit()
    }
}
