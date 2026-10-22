import CoreGraphics

/// Радиусы скругления из макетов Figma. Капсулы и круглые кнопки используют `GlassView.Shape.capsule`
/// или `cornerStyle = .capsule` вместо фиксированного значения.
enum Radius {
    /// Карточки, поля ввода и нижние панели.
    static let l: CGFloat = 24
}
