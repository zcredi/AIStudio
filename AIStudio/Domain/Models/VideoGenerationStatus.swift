import Foundation

/// Серверное состояние генерации, запущенной через `template2video`.
enum VideoGenerationStatus: Equatable, Sendable {
    case generating
    case succeeded(videoURL: URL)
    case failed
}
