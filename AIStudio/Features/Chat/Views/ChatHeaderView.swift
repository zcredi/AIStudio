import UIKit

/// Стеклянная панель: назад, аватар и имя ассистента, дата чата и меню действий.
final class ChatHeaderView: UIView {
    // MARK: - Types

    private enum Layout {
        static let contentHeight: CGFloat = 72
        static let sideInset = Spacing.l
        static let hitAreaSize: CGFloat = 44
        static let iconSize: CGFloat = 24
        /// Иконка назад 24 pt стоит в 16 pt от края; область нажатия 44 pt центрирована на ней.
        static let backButtonLeading = sideInset - (hitAreaSize - iconSize) / 2
        static let backToAvatarSpacing = Spacing.xxl
        static let avatarSize: CGFloat = 32
        static let avatarToTitleSpacing = Spacing.m
        static let titleSpacing = Spacing.xxs
        static let dateAlpha: CGFloat = 0.3
        static let moreButtonSize: CGFloat = 40
    }

    // MARK: - Properties

    var onBack: (() -> Void)?

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let pinView = UIImageView(image: UIImage(systemName: "pin.fill"))
    private let dateLabel = UILabel()
    private let moreButton: UIButton = {
        var configuration = UIButton.Configuration.adaptiveGlass()
        configuration.image = UIImage(resource: .moreIcon)
        configuration.contentInsets = .zero
        return UIButton(configuration: configuration)
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - API

    func render(date: String, isPinned: Bool, menu: UIMenu?) {
        dateLabel.text = date
        pinView.isHidden = !isPinned
        moreButton.menu = menu
        // Действия появляются с первым сообщением, как в макете.
        moreButton.isHidden = menu == nil
        titleLabel.accessibilityValue = isPinned ? String(localized: "Pinned") : nil
    }

    // MARK: - Private

    private func setupViews() {
        let glassView = GlassView(material: .regular, shape: .rectangle)
        addSubview(glassView)
        glassView.pinEdges(to: self)

        backButton.setImage(UIImage(resource: .backIcon), for: .normal)
        backButton.tintColor = Palette.textPrimary
        backButton.accessibilityLabel = String(localized: "Back")
        backButton.addAction(UIAction { [weak self] _ in self?.onBack?() }, for: .touchUpInside)

        titleLabel.text = String(localized: "AI Chat")
        titleLabel.font = Typography.semibold18
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary
        titleLabel.accessibilityTraits = .header

        pinView.tintColor = Palette.textSecondary
        pinView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        pinView.isHidden = true

        dateLabel.font = Typography.regular14
        dateLabel.adjustsFontForContentSizeCategory = true
        dateLabel.textColor = Palette.textPrimary.withAlphaComponent(Layout.dateAlpha)

        moreButton.showsMenuAsPrimaryAction = true
        moreButton.accessibilityLabel = String(localized: "Chat actions")
    }

    private func setupLayout() {
        let avatar = makeAvatar()
        let titleRow = UIStackView(arrangedSubviews: [titleLabel, pinView])
        titleRow.spacing = Spacing.xs
        titleRow.alignment = .center
        let titles = UIStackView(arrangedSubviews: [titleRow, dateLabel])
        titles.axis = .vertical
        titles.alignment = .leading
        titles.spacing = Layout.titleSpacing

        let content = UIView()
        addSubview(content)
        [content, backButton, avatar, titles, moreButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            if $0 !== content { content.addSubview($0) }
        }

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
            content.heightAnchor.constraint(equalToConstant: Layout.contentHeight),

            backButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: Layout.backButtonLeading),
            backButton.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: Layout.hitAreaSize),
            backButton.heightAnchor.constraint(equalToConstant: Layout.hitAreaSize),

            avatar.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: Layout.sideInset + Layout.iconSize + Layout.backToAvatarSpacing),
            avatar.centerYAnchor.constraint(equalTo: content.centerYAnchor),

            titles.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: Layout.avatarToTitleSpacing),
            titles.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            titles.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -Spacing.s),

            moreButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -Layout.sideInset),
            moreButton.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            moreButton.widthAnchor.constraint(equalToConstant: Layout.moreButtonSize),
            moreButton.heightAnchor.constraint(equalToConstant: Layout.moreButtonSize),
        ])
    }

    private func makeAvatar() -> UIView {
        let avatar = GradientView()
        avatar.layer.cornerRadius = Layout.avatarSize / 2
        avatar.clipsToBounds = true
        let iconView = UIImageView(image: UIImage(resource: .generateBMonoIcon))
        iconView.tintColor = Palette.textPrimary
        avatar.addSubview(iconView)
        [avatar, iconView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: Layout.avatarSize),
            avatar.heightAnchor.constraint(equalToConstant: Layout.avatarSize),
            iconView.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
        ])
        return avatar
    }
}
