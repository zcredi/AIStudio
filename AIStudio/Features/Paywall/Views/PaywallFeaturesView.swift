import UIKit

/// Маскот, заголовок и список преимуществ премиума.
final class PaywallFeaturesView: UIView {
    // MARK: - Types

    private enum Layout {
        static let mascotSize = CGSize(width: 135, height: 92)
        /// Маскот — квадратная картинка, обрезанная рамкой и сдвинутая вверх, как в макете.
        static let mascotImageTopOffset: CGFloat = -19.56
        static let mascotToTitleSpacing = Spacing.xxl
        static let titleToBenefitsSpacing: CGFloat = 32
        static let benefitSpacing = Spacing.s
        static let benefitIconSize: CGFloat = 24
        static let benefitRowHeight: CGFloat = 32
    }

    private struct Benefit {
        let icon: ImageResource
        let title: String
    }

    // MARK: - Properties

    /// Скрыт на коротких экранах, чтобы варианты покупки были видны без прокрутки.
    var isMascotHidden: Bool {
        get { mascotView.isHidden }
        set { mascotView.isHidden = newValue }
    }

    private lazy var mascotView = makeMascot()

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

    private static let benefits = [
        Benefit(icon: .generateBIcon, title: String(localized: "Get results in seconds")),
        Benefit(icon: .magicPencilAIcon, title: String(localized: "Turn any text into better writing")),
        Benefit(icon: .promptAIcon, title: String(localized: "Simplify complex information")),
        Benefit(icon: .imageToImageIcon, title: String(localized: "Create content with AI templates")),
    ]

    private func setupViews() {
        let titleLabel = UILabel()
        titleLabel.text = String(localized: "Create anything\nyou want")
        titleLabel.font = Typography.bold34
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header

        let benefitsStack = UIStackView(arrangedSubviews: Self.benefits.map(makeRow))
        benefitsStack.axis = .vertical
        benefitsStack.alignment = .leading
        benefitsStack.spacing = Layout.benefitSpacing

        let stack = UIStackView(arrangedSubviews: [mascotView, titleLabel, benefitsStack])
        stack.axis = .vertical
        stack.alignment = .center
        stack.setCustomSpacing(Layout.mascotToTitleSpacing, after: mascotView)
        stack.setCustomSpacing(Layout.titleToBenefitsSpacing, after: titleLabel)
        addSubview(stack)
        stack.pinEdges(to: self)
    }

    private func makeMascot() -> UIView {
        let container = UIView()
        container.clipsToBounds = true
        let imageView = UIImageView(image: UIImage(resource: .mascot))
        imageView.contentMode = .scaleAspectFill
        container.addSubview(imageView)

        [container, imageView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: Layout.mascotSize.width),
            container.heightAnchor.constraint(equalToConstant: Layout.mascotSize.height),
            imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: Layout.mascotImageTopOffset),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
        ])
        return container
    }

    private func makeRow(for benefit: Benefit) -> UIView {
        let iconView = UIImageView(image: UIImage(resource: benefit.icon))
        iconView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = benefit.title
        label.font = Typography.medium16
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Palette.textPrimary
        label.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [iconView, label])
        row.alignment = .center
        row.spacing = Spacing.s
        row.isAccessibilityElement = true
        row.accessibilityLabel = benefit.title

        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Layout.benefitIconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.benefitIconSize),
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.benefitRowHeight),
        ])
        return row
    }
}
