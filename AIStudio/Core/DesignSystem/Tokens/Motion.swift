import Foundation

/// Тайминги анимаций. Макеты статичные, поэтому значения следуют стандартам платформы.
enum Motion {
    /// Отклик на нажатие и небольшие переключения.
    static let fast: TimeInterval = 0.15
    /// Кроссфейды между загрузкой, контентом и ошибкой, а также изменения раскладки.
    static let standard: TimeInterval = 0.3
    /// Затухание пружин; при Reduce Motion пружины не используются вовсе.
    static let springDampingRatio: CGFloat = 0.85
    /// Масштаб контрола, пока он подсвечен.
    static let pressedScale: CGFloat = 0.96
}
