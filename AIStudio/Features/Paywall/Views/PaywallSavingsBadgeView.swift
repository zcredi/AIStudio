import UIKit

/// Капсула «SAVE 27%» на самом выгодном плане.
final class PaywallSavingsBadgeView: UIView {
    // MARK: - Types

    private enum Layout {
        static let insets = NSDirectionalEdgeInsets(top: 6, leading: Spacing.l, bottom: 6, trailing: Spacing.l)
    }

    // MARK: - Properties

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    private let gradientView = GradientView()
    private let label = UILabel()

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
        layer.cornerRadius = bounds.height / 2
    }

    // MARK: - Private

    private func setupViews() {
        clipsToBounds = true
        layer.cornerCurve = .continuous

        label.font = Typography.medium14
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Palette.textPrimary
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(gradientView)
        addSubview(label)
        gradientView.pinEdges(to: self)
        label.pinEdges(to: self, insets: Layout.insets)
    }
}
