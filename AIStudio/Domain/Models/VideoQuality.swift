import Foundation

/// Разрешение результата, которое принимает `template2video`.
enum VideoQuality: String, CaseIterable, Codable, Sendable {
    case p360 = "360p"
    case p540 = "540p"
    case p720 = "720p"
    case p1080 = "1080p"

    /// Выбирается по умолчанию, если шаблон его поддерживает.
    static let recommended = VideoQuality.p1080
}

// MARK: - Comparable

extension VideoQuality: Comparable {
    static func < (lhs: VideoQuality, rhs: VideoQuality) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        switch self {
        case .p360: 0
        case .p540: 1
        case .p720: 2
        case .p1080: 3
        }
    }
}
