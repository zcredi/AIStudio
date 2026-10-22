import UIKit

/// Иконка, заголовок и подсказка для списка, в котором пока ничего нет.
final class EmptyStateView: UIView {
    // MARK: - Types

    private enum Layout {
        static let iconSize: CGFloat = 48
        static let iconToTitleSpacing = Spacing.l
        static let titleToSubtitleSpacing = Spacing.s
        static let sideInset = Spacing.xxl
        static let titleKern: CGFloat = 0.4
        static let subtitleColor = Palette.textPrimary.withAlphaComponent(0.6)
    }

    // MARK: - Init

    init(icon: UIImage, title: String, subtitle: String) {
        super.init(frame: .zero)
        setupViews(icon: icon, title: title, subtitle: subtitle)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupViews(icon: UIImage, title: String, subtitle: String) {
        isAccessibilityElement = true
        accessibilityLabel = "\(title). \(subtitle)"

        let iconView = UIImageView(image: icon)
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.attributedText = NSAttributedString(
            string: title,
            attributes: [.font: Typography.bold28, .kern: Layout.titleKern, .foregroundColor: Palette.textPrimary]
        )
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = Typography.regular16
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = Layout.subtitleColor
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.setCustomSpacing(Layout.iconToTitleSpacing, after: iconView)
        stack.setCustomSpacing(Layout.titleToSubtitleSpacing, after: titleLabel)
        addSubview(stack)

        [stack, iconView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.sideInset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.sideInset),
        ])
    }
}
