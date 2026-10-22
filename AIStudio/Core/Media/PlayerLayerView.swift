import AVFoundation
import UIKit

/// Вид на основе `AVPlayerLayer`, который заполняет свои границы видео.
final class PlayerLayerView: UIView {
    // MARK: - Properties

    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        // Безопасно: `layerClass` гарантирует тип.
        layer as! AVPlayerLayer
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
