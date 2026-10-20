import Foundation

/// Animation timings. The mockups are static, so these follow platform defaults.
enum Motion {
    /// Press feedback and small toggles.
    static let fast: TimeInterval = 0.15
    /// Crossfades between loading, content and error, and layout changes.
    static let standard: TimeInterval = 0.3
    /// Damping for springs; skipped entirely when Reduce Motion is on.
    static let springDampingRatio: CGFloat = 0.85
    /// Scale applied to a control while it is highlighted.
    static let pressedScale: CGFloat = 0.96
}
