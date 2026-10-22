import Foundation

/// Эффект из каталога PixVerse, который превращает фото в видео.
struct VideoTemplate: Identifiable, Equatable, Sendable {
    /// `template_id` PixVerse — значение, которое ждёт `template2video`.
    let id: Int
    let name: String
    let category: String
    /// Качества, которые умеет этот шаблон, от низкого к высокому.
    let qualities: [VideoQuality]
    let previewURL: URL
    /// Превью в более высоком разрешении для экрана шаблона.
    let largePreviewURL: URL
}
