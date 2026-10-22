import Foundation

/// Ответ `get_templates`. В спеке он не типизирован, поэтому поля повторяют живой ответ
/// и сделаны опциональными: один битый шаблон не должен прятать весь каталог.
struct PixVerseCatalogDTO: Decodable, Sendable {
    let templates: [PixVerseTemplateDTO]
}

struct PixVerseTemplateDTO: Decodable, Sendable {
    let templateID: Int?
    let name: String?
    let category: String?
    let qualities: [String]?
    let previewSmall: String?
    let previewLarge: String?
    let isActive: Bool?

    private enum CodingKeys: String, CodingKey {
        case templateID = "template_id"
        case name
        case category
        case qualities
        case previewSmall = "preview_small"
        case previewLarge = "preview_large"
        case isActive = "is_active"
    }
}

/// `PixverseT2vResponse` в спеке API.
struct PixVerseGenerationDTO: Decodable, Sendable {
    let videoID: Int

    private enum CodingKeys: String, CodingKey {
        case videoID = "video_id"
    }
}

/// `PixverseGenerationStatusResponse` в спеке API.
struct PixVerseStatusDTO: Decodable, Sendable {
    let status: String
    let videoURL: String?

    private enum CodingKeys: String, CodingKey {
        case status
        case videoURL = "video_url"
    }
}
