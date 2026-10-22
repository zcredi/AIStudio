import UIKit

/// Чат в истории: иконка, название, последнее сообщение и булавка у закреплённых.
final class HistoryChatCell: UICollectionViewListCell {
    // MARK: - Types

    private enum Layout {
        static let insets = NSDirectionalEdgeInsets(top: Spacing.l, leading: Spacing.l, bottom: Spacing.l, trailing: Spacing.l)
        static let iconSize: CGFloat = 28
        static let pinSize: CGFloat = 24
        static let textSpacing = Spacing.xs
        static let cardColor = Palette.card.withAlphaComponent(0.4)
        static let previewAlpha: CGFloat = 0.5
    }

    // MARK: - Properties

    private let titleLabel = UILabel()
    private let previewLabel = UILabel()
    private let pinView = UIImageView(image: UIImage(resource: .pinIcon))

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

    override func updateConfiguration(using state: UICellConfigurationState) {
        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = Layout.cardColor
        background.cornerRadius = Radius.l
        backgroundConfiguration = background
        contentView.alpha = state.isHighlighted ? 0.7 : 1
    }

    // MARK: - API

    func configure(with row: ChatHistorySection.Row) {
        titleLabel.text = row.title
        previewLabel.text = row.preview
        previewLabel.isHidden = row.preview == nil
        pinView.isHidden = !row.isPinned
        accessibilityLabel = [row.title, row.preview].compactMap { $0 }.joined(separator: ", ")
        accessibilityValue = row.isPinned ? String(localized: "Pinned") : nil
    }

    // MARK: - Private

    private func setupViews() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        let iconView = UIImageView(image: UIImage(resource: .generateBIcon))
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = Typography.semibold16
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary

        previewLabel.font = Typography.regular14
        previewLabel.adjustsFontForContentSizeCategory = true
        previewLabel.textColor = Palette.textPrimary.withAlphaComponent(Layout.previewAlpha)

        pinView.tintColor = Palette.textPrimary
        pinView.setContentHuggingPriority(.required, for: .horizontal)

        let texts = UIStackView(arrangedSubviews: [titleLabel, previewLabel])
        texts.axis = .vertical
        texts.spacing = Layout.textSpacing

        let row = UIStackView(arrangedSubviews: [iconView, texts, pinView])
        row.alignment = .center
        row.spacing = Spacing.l
        contentView.addSubview(row)
        row.pinEdges(to: contentView, insets: Layout.insets)

        [iconView, pinView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),
            pinView.widthAnchor.constraint(equalToConstant: Layout.pinSize),
            pinView.heightAnchor.constraint(equalToConstant: Layout.pinSize),
        ])
    }
}
