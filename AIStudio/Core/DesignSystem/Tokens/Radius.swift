import CoreGraphics

/// Corner radii used in the Figma layouts. Pills and round buttons use `GlassView.Shape.capsule`
/// or `cornerStyle = .capsule` instead of a fixed value.
enum Radius {
    /// Cards, input fields and bottom panels.
    static let l: CGFloat = 24
}
