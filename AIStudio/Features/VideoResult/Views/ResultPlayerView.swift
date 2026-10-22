import AVFoundation
import UIKit

/// Сгенерированное видео в скруглённой карточке. На паузе оно затемнено, с кнопкой воспроизведения и «Replace»;
/// тап по карточке запускает или ставит на паузу. Воспроизведение зациклено.
final class ResultPlayerView: UIView {
    // MARK: - Types

    private enum Layout {
        static let cornerRadius = Radius.l
        static let replaceInset = Spacing.l
        static let replaceInsets = NSDirectionalEdgeInsets(top: Spacing.s, leading: Spacing.m, bottom: Spacing.s, trailing: Spacing.m)
    }

    // MARK: - Properties

    var onTogglePlayback: (() -> Void)?
    var onReplace: (() -> Void)?

    private let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private let playerView = PlayerLayerView()
    private let pausedOverlay = UIView()
    private let replaceButton = UIButton(type: .system)

    // MARK: - Init

    init(videoURL: URL) {
        super.init(frame: .zero)
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: videoURL))
        playerView.playerLayer.player = player
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    /// VoiceOver активирует само видео; распознаватель тапов такие активации не видит.
    override func accessibilityActivate() -> Bool {
        onTogglePlayback?()
        return true
    }

    // MARK: - API

    func render(isPlaying: Bool, isReplacing: Bool) {
        if isPlaying {
            player.play()
        } else {
            player.pause()
        }
        UIView.animate(withDuration: Motion.fast, delay: 0, options: [.beginFromCurrentState]) {
            self.pausedOverlay.alpha = isPlaying ? 0 : 1
        }
        pausedOverlay.isUserInteractionEnabled = !isPlaying
        replaceButton.configuration?.showsActivityIndicator = isReplacing
        replaceButton.isEnabled = !isReplacing
        accessibilityValue = isPlaying ? String(localized: "Playing") : String(localized: "Paused")
    }

    // MARK: - Private

    private func setupViews() {
        backgroundColor = Palette.card
        layer.cornerRadius = Layout.cornerRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true

        pausedOverlay.backgroundColor = Palette.dim
        let playIcon = UIImageView(image: UIImage(resource: .playLargeIcon))
        playIcon.tintColor = Palette.textPrimary

        var configuration = UIButton.Configuration.adaptiveGlass()
        configuration.image = UIImage(resource: .refreshIcon)
        configuration.imagePadding = Spacing.s
        configuration.contentInsets = Layout.replaceInsets
        configuration.title = String(localized: "Replace")
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Typography.regular14
            return attributes
        }
        replaceButton.configuration = configuration
        replaceButton.addAction(UIAction { [weak self] _ in self?.onReplace?() }, for: .touchUpInside)

        [playerView, pausedOverlay].forEach {
            addSubview($0)
            $0.pinEdges(to: self)
        }
        [playIcon, replaceButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            pausedOverlay.addSubview($0)
        }
        NSLayoutConstraint.activate([
            playIcon.centerXAnchor.constraint(equalTo: pausedOverlay.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: pausedOverlay.centerYAnchor),
            replaceButton.topAnchor.constraint(equalTo: pausedOverlay.topAnchor, constant: Layout.replaceInset),
            replaceButton.trailingAnchor.constraint(equalTo: pausedOverlay.trailingAnchor, constant: -Layout.replaceInset),
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        isAccessibilityElement = false
        playerView.isAccessibilityElement = true
        playerView.accessibilityLabel = String(localized: "Generated video")
        playerView.accessibilityTraits = [.button, .startsMediaSession]
        playerView.accessibilityHint = String(localized: "Plays or pauses the video")
    }

    @objc private func handleTap() {
        onTogglePlayback?()
    }
}
