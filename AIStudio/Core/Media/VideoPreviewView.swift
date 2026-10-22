import AVFoundation
import UIKit

/// Беззвучная поверхность для видео в ячейках. `AutoplayController` одалживает ей плеер, пока она на экране,
/// поэтому ячейки никогда не владеют плеерами. Видео проявляется поверх `posterImage`, когда готов первый кадр.
final class VideoPreviewView: UIView {
    // MARK: - Properties

    /// Что здесь должно играть. После изменения текущий плеер вернётся в пул при следующем обновлении.
    var videoURL: URL? {
        didSet {
            guard videoURL != oldValue else { return }
            playerView.alpha = 0
        }
    }

    var posterImage: UIImage? {
        get { posterView.image }
        set { posterView.image = newValue }
    }

    private let posterView = UIImageView()
    private let playerView = PlayerLayerView()
    private var readyObservation: NSKeyValueObservation?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - API

    /// Вызывает только `AutoplayController`.
    func attach(_ player: AVPlayer?) {
        guard playerView.playerLayer.player !== player else { return }
        playerView.playerLayer.player = player
        playerView.alpha = 0
        readyObservation = nil
        guard player != nil else { return }
        // KVO может прийти на любом потоке; проявление выполняется на главном акторе.
        readyObservation = playerView.playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in self?.showVideo() }
        }
    }

    // MARK: - Private

    private func setupViews() {
        clipsToBounds = true
        isAccessibilityElement = false
        posterView.contentMode = .scaleAspectFill
        playerView.alpha = 0
        [posterView, playerView].forEach {
            addSubview($0)
            $0.pinEdges(to: self)
        }
    }

    private func showVideo() {
        guard playerView.playerLayer.isReadyForDisplay, playerView.alpha == 0 else { return }
        UIView.animate(withDuration: Motion.fast) {
            self.playerView.alpha = 1
        }
    }
}
