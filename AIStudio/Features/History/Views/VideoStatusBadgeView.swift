import UIKit

/// Капсула на карточке видео в истории: «New», «In progress» или «Error» с цветной точкой.
final class VideoStatusBadgeView: UIView {
    // MARK: - Types

    enum Status {
        case new
        case inProgress
        case error
    }

    private enum Layout {
        static let insets = NSDirectionalEdgeInsets(top: Spacing.xs, leading: Spacing.s, bottom: Spacing.xs, trailing: 10)
        static let dotSize: CGFloat = 6
        static let dotSpacing: CGFloat = 5
        static let backgroundColor = Palette.background.withAlphaComponent(0.7)
        static let borderAlpha: CGFloat = 0.5
    }

    // MARK: - Properties

    private let dotView = UIView()
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
        layer.cornerRadius = bounds.height / 2
    }

    // MARK: - API

    func configure(with status: Status) {
        let color = status.color
        dotView.backgroundColor = color
        titleLabel.textColor = color
        titleLabel.text = status.title
        layer.borderColor = color.withAlphaComponent(Layout.borderAlpha).cgColor
    }

    // MARK: - Private

    private func setupViews() {
        backgroundColor = Layout.backgroundColor
        layer.borderWidth = 1
        dotView.layer.cornerRadius = Layout.dotSize / 2
        titleLabel.font = Typography.medium12
        titleLabel.adjustsFontForContentSizeCategory = true

        let row = UIStackView(arrangedSubviews: [dotView, titleLabel])
        row.alignment = .center
        row.spacing = Layout.dotSpacing
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = Layout.insets
        addSubview(row)
        row.pinEdges(to: self)
        dotView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: Layout.dotSize),
            dotView.heightAnchor.constraint(equalToConstant: Layout.dotSize),
        ])
    }
}

// MARK: - Status

private extension VideoStatusBadgeView.Status {
    var title: String {
        switch self {
        case .new: String(localized: "New")
        case .inProgress: String(localized: "In progress")
        case .error: String(localized: "Error")
        }
    }

    var color: UIColor {
        switch self {
        case .new: Palette.accentGreen
        case .inProgress: Palette.gradientStart
        case .error: Palette.actionRed
        }
    }
}
