import UIKit

/// Один вариант в `OptionsDropdownView`: необязательная иконка, заголовок, подзаголовок и галочка у выбранного.
final class DropdownOptionRow: UIControl {
    // MARK: - Types

    private enum Layout {
        static let insets = NSDirectionalEdgeInsets(top: Spacing.m, leading: Spacing.l, bottom: Spacing.m, trailing: Spacing.l)
        static let iconSize: CGFloat = 22
        static let iconConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        static let unselectedIconAlpha: CGFloat = 0.6
        static let unselectedTitleAlpha: CGFloat = 0.85
        static let subtitleAlpha: CGFloat = 0.45
        static let selectedBackground = Palette.textPrimary.withAlphaComponent(0.06)
        static let highlightedBackground = Palette.textPrimary.withAlphaComponent(0.1)
        static let separatorColor = Palette.textPrimary.withAlphaComponent(0.06)
        static let titleSpacing = Spacing.xxs
    }

    // MARK: - Properties

    override var isHighlighted: Bool {
        didSet { updateBackground() }
    }

    private let isChosen: Bool

    // MARK: - Init

    init(option: OptionsDropdownView.Option, showsSeparator: Bool) {
        isChosen = option.isSelected
        super.init(frame: .zero)
        setupViews(option: option, showsSeparator: showsSeparator)
        updateBackground()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupViews(option: OptionsDropdownView.Option, showsSeparator: Bool) {
        let titleLabel = UILabel()
        titleLabel.text = option.title
        titleLabel.font = Typography.medium16
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary.withAlphaComponent(option.isSelected ? 1 : Layout.unselectedTitleAlpha)

        let subtitleLabel = UILabel()
        subtitleLabel.text = option.subtitle
        subtitleLabel.font = Typography.regular12
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = Palette.textPrimary.withAlphaComponent(Layout.subtitleAlpha)

        let texts = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        texts.axis = .vertical
        texts.spacing = Layout.titleSpacing

        let checkView = UIImageView(image: UIImage(resource: .checkIcon))
        checkView.isHidden = !option.isSelected
        checkView.setContentHuggingPriority(.required, for: .horizontal)

        var arrangedSubviews: [UIView] = [texts, checkView]
        if let symbolName = option.symbolName {
            arrangedSubviews.insert(makeIcon(symbolName: symbolName, isSelected: option.isSelected), at: 0)
        }
        let row = UIStackView(arrangedSubviews: arrangedSubviews)
        row.alignment = .center
        row.spacing = Spacing.m
        row.isUserInteractionEnabled = false
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = Layout.insets
        addSubview(row)
        row.pinEdges(to: self)

        if showsSeparator {
            addSeparator()
        }

        isAccessibilityElement = true
        accessibilityLabel = option.title
        accessibilityHint = option.subtitle
        accessibilityTraits = option.isSelected ? [.button, .selected] : .button
    }

    private func makeIcon(symbolName: String, isSelected: Bool) -> UIView {
        let iconView = UIImageView(image: UIImage(systemName: symbolName, withConfiguration: Layout.iconConfiguration))
        iconView.contentMode = .center
        iconView.tintColor = Palette.textPrimary.withAlphaComponent(isSelected ? 1 : Layout.unselectedIconAlpha)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),
        ])
        return iconView
    }

    private func addSeparator() {
        let separator = UIView()
        separator.backgroundColor = Layout.separatorColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    private func updateBackground() {
        if isHighlighted {
            backgroundColor = Layout.highlightedBackground
        } else {
            backgroundColor = isChosen ? Layout.selectedBackground : .clear
        }
    }
}
