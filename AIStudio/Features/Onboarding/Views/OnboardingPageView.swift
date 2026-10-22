import UIKit

/// Заголовок, подзаголовок и иллюстрация одной страницы онбординга.
final class OnboardingPageView: UIView {
    // MARK: - Types

    private enum Layout {
        static let titleTopSpacing: CGFloat = 56
        static let titleSpacing = Spacing.m
        static let sideInset = Spacing.l
        static let subtitleColor = Palette.textPrimary.withAlphaComponent(0.6)
        static let illustrationMinimumTopSpacing = Spacing.l
        static let illustrationMinimumBottomSpacing = Spacing.s
        /// Отступ между иллюстрацией и индикатором страниц на макете высотой 844 pt.
        static let illustrationBottomSpacing: CGFloat = 49
        /// Иллюстрации вырезаны из полноэкранного арта; растворение верхнего края прячет стык со свечением.
        static let illustrationFadeHeight: CGFloat = 24
    }

    // MARK: - Properties

    private let illustrationView = UIImageView()
    private let illustrationMask = CAGradientLayer()

    // MARK: - Init

    init(page: OnboardingPage) {
        super.init(frame: .zero)
        setupViews(for: page)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = illustrationView.bounds
        guard bounds.height > 0 else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        illustrationMask.frame = bounds
        illustrationMask.locations = [0, NSNumber(value: Double(Layout.illustrationFadeHeight / bounds.height))]
        CATransaction.commit()
    }

    // MARK: - Private

    private func setupViews(for page: OnboardingPage) {
        let titleLabel = makeLabel(text: page.title, font: Typography.bold28, color: Palette.textPrimary)
        titleLabel.accessibilityTraits = .header
        let subtitleLabel = makeLabel(text: page.subtitle, font: Typography.regular16, color: Layout.subtitleColor)

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = Layout.titleSpacing

        let image = UIImage(resource: page.illustration)
        illustrationView.image = image
        illustrationView.contentMode = .scaleAspectFit
        // Естественный размер картинки не должен спорить с текстом за место на коротких экранах.
        illustrationView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        illustrationView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        illustrationView.isAccessibilityElement = false
        illustrationMask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        illustrationView.layer.mask = illustrationMask

        [titleStack, illustrationView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        setupLayout(titleStack: titleStack, illustrationAspectRatio: image.size.width / image.size.height)
    }

    private func setupLayout(titleStack: UIView, illustrationAspectRatio: CGFloat) {
        // Во всю ширину, как в макете; на коротких экранах иллюстрация уменьшается, чтобы не наезжать на текст.
        // Оба приоритета ниже сопротивления сжатию у лейблов, поэтому текст никогда не сжимается,
        // а сохранение размера важнее сохранения позиции из макета.
        let fullWidth = illustrationView.widthAnchor.constraint(equalTo: widthAnchor)
        fullWidth.priority = UILayoutPriority(UILayoutPriority.defaultHigh.rawValue - 1)
        let mockupBottom = illustrationView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.illustrationBottomSpacing)
        mockupBottom.priority = UILayoutPriority(UILayoutPriority.defaultHigh.rawValue - 2)

        NSLayoutConstraint.activate([
            titleStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.titleTopSpacing),
            titleStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.sideInset),
            titleStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.sideInset),

            illustrationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            illustrationView.widthAnchor.constraint(equalTo: illustrationView.heightAnchor, multiplier: illustrationAspectRatio),
            illustrationView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            illustrationView.topAnchor.constraint(greaterThanOrEqualTo: titleStack.bottomAnchor, constant: Layout.illustrationMinimumTopSpacing),
            illustrationView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Layout.illustrationMinimumBottomSpacing),
            fullWidth,
            mockupBottom,
        ])
    }

    private func makeLabel(text: String, font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
}

// MARK: - OnboardingPage

private extension OnboardingPage {
    var illustration: ImageResource {
        switch self {
        case .chat:
            .onboardingChat
        case .video:
            .onboardingVideo
        }
    }
}
