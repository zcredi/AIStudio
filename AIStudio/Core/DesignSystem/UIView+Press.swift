import UIKit

extension UIView {
    /// Слегка уменьшает контрол при нажатии. С Reduce Motion контрол не меняется.
    func animatePress(isPressed: Bool) {
        let isScaled = isPressed && !UIAccessibility.isReduceMotionEnabled
        let transform = isScaled ? CGAffineTransform(scaleX: Motion.pressedScale, y: Motion.pressedScale) : .identity
        UIView.animate(
            withDuration: Motion.fast,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction]
        ) {
            self.transform = transform
        }
    }
}
