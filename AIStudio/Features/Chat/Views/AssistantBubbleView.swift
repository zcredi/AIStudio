import UIKit

/// Тёмный пузырь сообщений ассистента с острым нижним левым углом.
final class AssistantBubbleView: UIView {
    // MARK: - Types

    private enum Layout {
        static let cornerRadius = Radius.l
        static let backgroundColor = Palette.card.withAlphaComponent(0.5)
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Layout.backgroundColor
        layer.cornerRadius = Layout.cornerRadius
        layer.cornerCurve = .continuous
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
