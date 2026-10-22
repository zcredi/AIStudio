import UIKit

/// Карточка «Turn Photo into Video», которая открывает генератор видео.
final class VideoFeatureCard: UIControl {
    // MARK: - Types

    private enum Layout {
        static let cornerRadius = Radius.l
        static let insets = NSDirectionalEdgeInsets(top: Spacing.xl, leading: Spacing.xl, bottom: Spacing.xl, trailing: Spacing.xl)
        static let gradientAlpha: CGFloat = 0.8
        /// CSS-градиент 168.6° из Figma, пересчитанный в единичные координаты карточки.
        static let gradientStart = CGPoint(x: 0.43, y: -0.19)
        static let gradientEnd = CGPoint(x: 0.57, y: 1.37)
        static let gradientLocations: [NSNumber] = [0.036, 0.861]
        static let streakTopOffset: CGFloat = 43
        static let streakAlpha: CGFloat = 0.5
        static let bubbleSize: CGFloat = 36
        static let bubbleIconSize: CGFloat = 20
        static let columnSpacing = Spacing.m
        static let textSpacing = Spacing.s
        static let metaAlpha: CGFloat = 0.7
        static let dotSize: CGFloat = 4
        static let pillHeight: CGFloat = 32
        static let pillInsets = NSDirectionalEdgeInsets(top: 0, leading: Spacing.m, bottom: 0, trailing: Spacing.m)
        static let pillKern: CGFloat = 0.06
        static let playIconSize: CGFloat = 16
    }

    // MARK: - Properties

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            animatePress(isPressed: isHighlighted)
        }
    }

    private let gradientLayer = CAGradientLayer()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBackground()
        setupContent()
        setupAccessibility()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }

    // MARK: - Private

    private func setupBackground() {
        layer.cornerRadius = Layout.cornerRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true

        gradientLayer.colors = [Palette.gradientStart, Palette.gradientEnd].map {
            $0.withAlphaComponent(Layout.gradientAlpha).cgColor
        }
        gradientLayer.locations = Layout.gradientLocations
        gradientLayer.startPoint = Layout.gradientStart
        gradientLayer.endPoint = Layout.gradientEnd
        layer.addSublayer(gradientLayer)

        let streakView = UIImageView(image: UIImage(resource: .videoCardStreak))
        streakView.alpha = Layout.streakAlpha
        streakView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(streakView)
        NSLayoutConstraint.activate([
            streakView.topAnchor.constraint(equalTo: topAnchor, constant: Layout.streakTopOffset),
            streakView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    private func setupContent() {
        let titleLabel = UILabel()
        titleLabel.text = String(localized: "Turn Photo\ninto Video")
        titleLabel.font = Typography.medium20
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary
        titleLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, makeMetaRow()])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = Layout.textSpacing

        let column = UIStackView(arrangedSubviews: [makeIconBubble(), textStack])
        column.axis = .vertical
        column.alignment = .leading
        column.spacing = Layout.columnSpacing

        let pill = makePill()
        [column, pill].forEach {
            $0.isUserInteractionEnabled = false
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        let insets = Layout.insets
        NSLayoutConstraint.activate([
            column.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            column.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading),
            column.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            column.trailingAnchor.constraint(lessThanOrEqualTo: pill.leadingAnchor, constant: -Spacing.s),
            pill.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            pill.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.trailing),
        ])
    }

    private func makeIconBubble() -> UIView {
        let bubble = GlassView(material: .clear, shape: .capsule)
        let iconView = UIImageView(image: UIImage(resource: .imageToImageMonoIcon))
        iconView.tintColor = Palette.textPrimary
        iconView.contentMode = .scaleAspectFit
        bubble.contentView.addSubview(iconView)
        [bubble, iconView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            bubble.widthAnchor.constraint(equalToConstant: Layout.bubbleSize),
            bubble.heightAnchor.constraint(equalToConstant: Layout.bubbleSize),
            iconView.widthAnchor.constraint(equalToConstant: Layout.bubbleIconSize),
            iconView.heightAnchor.constraint(equalToConstant: Layout.bubbleIconSize),
            iconView.centerXAnchor.constraint(equalTo: bubble.contentView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: bubble.contentView.centerYAnchor),
        ])
        return bubble
    }

    private func makeMetaRow() -> UIView {
        let dot = UIView()
        dot.backgroundColor = Palette.textPrimary
        dot.layer.cornerRadius = Layout.dotSize / 2
        dot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: Layout.dotSize),
            dot.heightAnchor.constraint(equalToConstant: Layout.dotSize),
        ])

        let row = UIStackView(arrangedSubviews: [
            makeMetaLabel(String(localized: "Animate")),
            dot,
            makeMetaLabel(String(localized: "Templates")),
        ])
        row.alignment = .center
        row.spacing = Spacing.s
        row.alpha = Layout.metaAlpha
        return row
    }

    private func makeMetaLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = Typography.regular14
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Palette.textPrimary
        return label
    }

    private func makePill() -> UIView {
        let pill = GlassView(material: .clear, shape: .capsule)

        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: String(localized: "Ready in seconds"),
            attributes: [.font: Typography.regular12, .kern: Layout.pillKern, .foregroundColor: Palette.textPrimary]
        )
        label.adjustsFontForContentSizeCategory = true

        let playView = UIImageView(image: UIImage(resource: .playIcon))
        playView.tintColor = Palette.textPrimary
        playView.contentMode = .center
        // Многоугольник в Figma смотрит вверх и повёрнут, чтобы смотреть вправо.
        playView.transform = CGAffineTransform(rotationAngle: .pi / 2)

        let row = UIStackView(arrangedSubviews: [label, playView])
        row.alignment = .center
        row.spacing = Spacing.s
        pill.contentView.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        pill.translatesAutoresizingMaskIntoConstraints = false
        playView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pill.heightAnchor.constraint(equalToConstant: Layout.pillHeight),
            row.leadingAnchor.constraint(equalTo: pill.contentView.leadingAnchor, constant: Layout.pillInsets.leading),
            row.trailingAnchor.constraint(equalTo: pill.contentView.trailingAnchor, constant: -Layout.pillInsets.trailing),
            row.centerYAnchor.constraint(equalTo: pill.contentView.centerYAnchor),
            playView.widthAnchor.constraint(equalToConstant: Layout.playIconSize),
            playView.heightAnchor.constraint(equalToConstant: Layout.playIconSize),
        ])
        return pill
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = String(localized: "Turn Photo into Video")
        accessibilityValue = String(localized: "Animate, Templates. Ready in seconds")
    }
}
