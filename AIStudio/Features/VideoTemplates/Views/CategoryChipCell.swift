import UIKit

/// Фильтр категории: фирменный градиент у выбранной, приглушённая капсула у остальных.
final class CategoryChipCell: UICollectionViewCell {
    // MARK: - Types

    private enum Layout {
        static let insets = NSDirectionalEdgeInsets(top: Spacing.s, leading: Spacing.l, bottom: Spacing.s, trailing: Spacing.l)
        static let minimumWidth: CGFloat = 76
        static let normalColor = Palette.card.withAlphaComponent(0.6)
        static let normalTextAlpha: CGFloat = 0.5
    }

    // MARK: - Properties

    override var isSelected: Bool {
        didSet {
            guard isSelected != oldValue else { return }
            // Переиспользуемые ячейки получают состояние без анимации; тап на экране меняет его плавно.
            guard window != nil else {
                updateAppearance()
                return
            }
            UIView.transition(with: contentView, duration: Motion.fast, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                self.updateAppearance()
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            animatePress(isPressed: isHighlighted)
        }
    }

    private let gradientView = GradientView()
    private let titleLabel = UILabel()

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
        contentView.layer.cornerRadius = bounds.height / 2
    }

    // MARK: - API

    func configure(with title: String) {
        titleLabel.text = title
        accessibilityLabel = title
    }

    // MARK: - Private

    private func setupViews() {
        contentView.backgroundColor = Layout.normalColor
        contentView.clipsToBounds = true
        contentView.layer.cornerCurve = .continuous
        contentView.addSubview(gradientView)
        gradientView.pinEdges(to: contentView)

        titleLabel.font = Typography.regular14
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        titleLabel.pinEdges(to: contentView, insets: Layout.insets)
        let minimumTitleWidth = Layout.minimumWidth - Layout.insets.leading - Layout.insets.trailing
        titleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumTitleWidth).isActive = true

        isAccessibilityElement = true
        updateAppearance()
    }

    private func updateAppearance() {
        gradientView.isHidden = !isSelected
        titleLabel.textColor = Palette.textPrimary.withAlphaComponent(isSelected ? 1 : Layout.normalTextAlpha)
        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
}
