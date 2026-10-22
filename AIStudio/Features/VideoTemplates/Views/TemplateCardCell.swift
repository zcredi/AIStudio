import UIKit

/// Шаблон в сетке: зацикленное превью и название поверх тёмного затемнения.
final class TemplateCardCell: UICollectionViewCell, VideoPreviewProviding {
    // MARK: - Types

    private enum Layout {
        static let cornerRadius = Radius.l
        static let titleInsets = NSDirectionalEdgeInsets(top: 0, leading: Spacing.s, bottom: Spacing.s, trailing: Spacing.s)
        static let fadeColor = Palette.card.withAlphaComponent(0.6)
    }

    // MARK: - Properties

    let videoPreview = VideoPreviewView()

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            animatePress(isPressed: isHighlighted)
        }
    }

    private let fadeLayer = CAGradientLayer()
    private let titleLabel = UILabel()

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

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fadeLayer.frame = contentView.bounds
        CATransaction.commit()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        videoPreview.videoURL = nil
    }

    // MARK: - API

    func configure(with template: VideoTemplate) {
        titleLabel.text = template.name
        videoPreview.videoURL = template.previewURL
        accessibilityLabel = template.name
    }

    // MARK: - Private

    private func setupViews() {
        contentView.backgroundColor = Palette.card
        contentView.layer.cornerRadius = Layout.cornerRadius
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        contentView.addSubview(videoPreview)
        videoPreview.pinEdges(to: contentView)

        fadeLayer.colors = [Layout.fadeColor.withAlphaComponent(0).cgColor, Layout.fadeColor.cgColor]
        contentView.layer.addSublayer(fadeLayer)

        titleLabel.font = Typography.regular16
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = Palette.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.titleInsets.leading),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.titleInsets.trailing),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.titleInsets.bottom),
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}
