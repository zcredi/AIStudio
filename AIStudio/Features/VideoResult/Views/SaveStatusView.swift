import UIKit

/// Карточка по центру, которая сообщает, сохранилось ли видео в «Фото».
final class SaveStatusView: UIView {
    // MARK: - Types

    enum Status {
        case saved
        case failed
    }

    private enum Layout {
        static let width: CGFloat = 239
        static let insets = NSDirectionalEdgeInsets(top: Spacing.xxl, leading: Spacing.l, bottom: Spacing.xxl, trailing: Spacing.l)
        static let iconConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        static let iconSpacing = Spacing.m
        static let textSpacing = Spacing.xs
        static let subtitleAlpha: CGFloat = 0.6
    }

    // MARK: - Init

    init(status: Status) {
        super.init(frame: .zero)
        setupViews(status: status)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupViews(status: Status) {
        let glassView = GlassView(material: .menu, shape: .roundedRect(cornerRadius: Radius.l))
        addSubview(glassView)
        glassView.pinEdges(to: self)

        let iconView = UIImageView(image: UIImage(systemName: status.symbolName, withConfiguration: Layout.iconConfiguration))
        iconView.tintColor = status.iconColor

        let titleLabel = UILabel()
        titleLabel.text = status.title
        titleLabel.font = Typography.semibold16
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = status.subtitle
        subtitleLabel.font = Typography.regular14
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = Palette.textPrimary.withAlphaComponent(Layout.subtitleAlpha)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Layout.textSpacing
        stack.setCustomSpacing(Layout.iconSpacing, after: iconView)
        glassView.contentView.addSubview(stack)
        stack.pinEdges(to: glassView.contentView, insets: Layout.insets)
        widthAnchor.constraint(equalToConstant: Layout.width).isActive = true

        isAccessibilityElement = true
        accessibilityLabel = "\(status.title). \(status.subtitle)"
    }
}

// MARK: - Status

private extension SaveStatusView.Status {
    var symbolName: String {
        switch self {
        case .saved: "checkmark"
        case .failed: "xmark"
        }
    }

    var iconColor: UIColor {
        switch self {
        case .saved: Palette.textPrimary
        case .failed: Palette.actionRed
        }
    }

    var title: String {
        switch self {
        case .saved: String(localized: "Video saved")
        case .failed: String(localized: "Couldn’t save video")
        }
    }

    var subtitle: String {
        switch self {
        case .saved: String(localized: "You can find it in your Photos")
        case .failed: String(localized: "Please try again")
        }
    }
}
