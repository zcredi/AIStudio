import UIKit

/// Стеклянная панель: назад, аватар генератора и заголовок «AI Video».
final class VideoTemplatesHeaderView: UIView {
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
    }

    // MARK: - Properties

    var onBack: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupViews() {
        let glassView = GlassView(material: .regular, shape: .rectangle)
        addSubview(glassView)
        glassView.pinEdges(to: self)

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(resource: .backIcon), for: .normal)
        backButton.tintColor = Palette.textPrimary
        backButton.accessibilityLabel = String(localized: "Back")
        backButton.addAction(UIAction { [weak self] _ in self?.onBack?() }, for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = String(localized: "AI Video")
        titleLabel.font = Typography.semibold18
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary
        titleLabel.accessibilityTraits = .header

        let content = UIView()
        let avatar = makeAvatar()
        addSubview(content)
        [content, backButton, avatar, titleLabel].forEach {
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

            titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: Layout.avatarToTitleSpacing),
            titleLabel.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -Layout.sideInset),
        ])
    }

    private func makeAvatar() -> UIView {
        let avatar = GradientView()
        avatar.layer.cornerRadius = Layout.avatarSize / 2
        avatar.clipsToBounds = true
        let iconView = UIImageView(image: UIImage(resource: .imageToImageMonoIcon))
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
