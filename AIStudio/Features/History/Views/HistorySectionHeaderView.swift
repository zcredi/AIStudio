import UIKit

/// Заголовок группы чатов в истории, например «Pinned» или «Today».
final class HistorySectionHeaderView: UICollectionReusableView {
    // MARK: - Properties

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    private let titleLabel = UILabel()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = Typography.semibold20
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary
        titleLabel.accessibilityTraits = .header
        addSubview(titleLabel)
        // Секции списка не сдвигают заголовки, поэтому заголовок сам держит боковой отступ карточек.
        titleLabel.pinEdges(to: self, insets: NSDirectionalEdgeInsets(top: 0, leading: Spacing.l, bottom: 0, trailing: Spacing.l))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
