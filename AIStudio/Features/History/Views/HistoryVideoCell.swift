import UIKit

/// Сгенерированное видео в истории. Готовые видео играют через `AutoplayController`; остальные показывают
/// размытый стартовый кадр с прогрессом или кнопкой «Try again».
final class HistoryVideoCell: UICollectionViewCell, VideoPreviewProviding {
    // MARK: - Types

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let badgeInset = Spacing.s
        static let overlayColor = Palette.background.withAlphaComponent(0.55)
        /// В Figma стартовый кадр размыт на 6 pt; битмап размывается в пикселях.
        static let blurRadius: CGFloat = 6
        static let captionAlpha: CGFloat = 0.85
        static let captionSpacing = Spacing.s
        static let retryInsets = NSDirectionalEdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)
        static let retryBackground = Palette.textPrimary.withAlphaComponent(0.14)
        /// Спиннер в макете 32 pt, а большой системный — 37 pt.
        static let spinnerScale: CGFloat = 32 / 37
        static let contentInset = Spacing.s
    }

    // MARK: - Properties

    let videoPreview = VideoPreviewView()
    var onRetry: (() -> Void)?

    private let overlayView = UIView()
    private let badgeView = VideoStatusBadgeView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let progressStack = UIStackView()
    private let failureStack = UIStackView()
    private var posterTask: Task<Void, Never>?

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            animatePress(isPressed: isHighlighted)
        }
    }

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

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        posterTask?.cancel()
        posterTask = nil
        videoPreview.posterImage = nil
        videoPreview.videoURL = nil
        onRetry = nil
    }

    // MARK: - API

    func configure(with item: HistoryViewModel.VideoItem, thumbnails: ThumbnailLoader) {
        let isReady = item.state == .ready
        videoPreview.videoURL = isReady ? item.videoURL : nil
        overlayView.isHidden = isReady
        progressStack.isHidden = item.state != .inProgress
        failureStack.isHidden = item.state != .failed
        if item.state == .inProgress {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }

        let status = item.badgeStatus
        badgeView.isHidden = status == nil
        if let status {
            badgeView.configure(with: status)
        }
        loadPoster(from: item.startFrameURL, isBlurred: !isReady, thumbnails: thumbnails)
        configureAccessibility(for: item)
    }

    // MARK: - Private

    private func setupViews() {
        contentView.backgroundColor = Palette.card
        contentView.layer.cornerRadius = Layout.cornerRadius
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        overlayView.backgroundColor = Layout.overlayColor
        spinner.color = Palette.textPrimary
        spinner.transform = CGAffineTransform(scaleX: Layout.spinnerScale, y: Layout.spinnerScale)

        configure(progressStack, arrangedSubviews: [spinner, makeCaption(String(localized: "Generating…"))])
        configure(failureStack, arrangedSubviews: [makeCaption(String(localized: "Something went wrong")), makeRetryButton()])
    }

    private func setupLayout() {
        [videoPreview, overlayView].forEach {
            contentView.addSubview($0)
            $0.pinEdges(to: contentView)
        }
        [progressStack, failureStack, badgeView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        var constraints = [
            badgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.badgeInset),
            badgeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.badgeInset),
            badgeView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -Layout.badgeInset),
        ]
        for stack in [progressStack, failureStack] {
            constraints += [
                stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                stack.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: Layout.contentInset),
            ]
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func configure(_ stack: UIStackView, arrangedSubviews: [UIView]) {
        arrangedSubviews.forEach(stack.addArrangedSubview)
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Layout.captionSpacing
    }

    private func makeCaption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = Typography.medium13
        label.adjustsFontForContentSizeCategory = true
        label.textColor = Palette.textPrimary.withAlphaComponent(Layout.captionAlpha)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    private func makeRetryButton() -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = String(localized: "Try again")
        configuration.baseForegroundColor = Palette.textPrimary
        configuration.background.backgroundColor = Layout.retryBackground
        configuration.cornerStyle = .capsule
        configuration.contentInsets = Layout.retryInsets
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Typography.semibold13
            return attributes
        }
        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)
        return button
    }

    private func loadPoster(from url: URL, isBlurred: Bool, thumbnails: ThumbnailLoader) {
        posterTask?.cancel()
        let scale = traitCollection.displayScale
        let longestSide = max(bounds.width, bounds.height)
        let maxPixelSize = Int(longestSide * scale)
        let blurRadius = isBlurred ? Layout.blurRadius * scale : 0
        posterTask = Task { [weak self, thumbnails] in
            let image = await thumbnails.thumbnail(for: url, maxPixelSize: max(maxPixelSize, 1), blurRadius: blurRadius)
            guard !Task.isCancelled else { return }
            self?.videoPreview.posterImage = image
        }
    }

    private func configureAccessibility(for item: HistoryViewModel.VideoItem) {
        isAccessibilityElement = item.state != .failed
        accessibilityLabel = item.title
        accessibilityTraits = item.state == .failed ? .none : .button
        switch item.state {
        case .ready:
            accessibilityValue = item.isNew ? String(localized: "New") : nil
        case .inProgress:
            accessibilityValue = String(localized: "Generating")
        case .failed:
            accessibilityValue = nil
        }
    }
}

// MARK: - Badge

private extension HistoryViewModel.VideoItem {
    var badgeStatus: VideoStatusBadgeView.Status? {
        switch state {
        case .ready: isNew ? .new : nil
        case .inProgress: .inProgress
        case .failed: .error
        }
    }
}
