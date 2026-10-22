import Foundation

struct VideoGenerationRequest: Sendable {
    let templateID: VideoTemplate.ID
    let templateName: String
    let format: VideoFormat
    let quality: VideoQuality
    /// Выбранное фото в JPEG; перед загрузкой обрезается под `format`.
    let photo: Data
}
