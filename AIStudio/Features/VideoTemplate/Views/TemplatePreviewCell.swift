import UIKit

/// Шаблон в карусели, проигрывает своё большое превью.
final class TemplatePreviewCell: UICollectionViewCell, VideoPreviewProviding {
    // MARK: - Types

    private enum Layout {
        static let cornerRadius: CGFloat = 16
    }

    // MARK: - Properties

    let videoPreview = VideoPreviewView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = Palette.card
        contentView.layer.cornerRadius = Layout.cornerRadius
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        contentView.addSubview(videoPreview)
        videoPreview.pinEdges(to: contentView)
        isAccessibilityElement = true
        accessibilityTraits = .image
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        videoPreview.videoURL = nil
    }

    // MARK: - API

    func configure(with template: VideoTemplate) {
        videoPreview.videoURL = template.largePreviewURL
        accessibilityLabel = String(localized: "\(template.name) preview")
    }
}
