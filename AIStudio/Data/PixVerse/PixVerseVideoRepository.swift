import Foundation

struct PixVerseVideoRepository: VideoTemplateRepository, VideoGenerationRepository {
    // MARK: - Properties

    private let client: any APIClient
    private let appID: String

    // MARK: - Init

    init(client: any APIClient, appID: String) {
        self.client = client
        self.appID = appID
    }

    // MARK: - VideoTemplateRepository

    func templates() async throws -> [VideoTemplate] {
        try await client.send(PixVerseAPI.templates(appID: appID)).templates.compactMap(VideoTemplate.init)
    }

    // MARK: - VideoGenerationRepository

    func startGeneration(templateID: Int, image: Data, quality: VideoQuality) async throws -> Int {
        let endpoint = PixVerseAPI.templateToVideo(templateID: templateID, image: image, quality: quality.rawValue)
        return try await client.send(endpoint).videoID
    }

    func status(ofGeneration id: Int) async throws -> VideoGenerationStatus {
        try VideoGenerationStatus(await client.send(PixVerseAPI.status(generationID: id)))
    }
}

// MARK: - Mapping

private extension VideoTemplate {
    /// Возвращает `nil` для неактивных шаблонов и для записей без ID, названия или превью.
    init?(_ dto: PixVerseTemplateDTO) {
        guard
            dto.isActive != false,
            let id = dto.templateID,
            let name = dto.name,
            let previewURL = dto.previewSmall.flatMap(URL.init(string:))
        else {
            return nil
        }
        // Без списка шаблон принимает любое качество, которое поддерживает эндпоинт.
        let qualities = Set((dto.qualities ?? []).compactMap(VideoQuality.init(rawValue:)))
        self.init(
            id: id,
            name: name,
            category: dto.category ?? String(localized: "Other"),
            qualities: qualities.isEmpty ? VideoQuality.allCases : qualities.sorted(),
            previewURL: previewURL,
            largePreviewURL: dto.previewLarge.flatMap(URL.init(string:)) ?? previewURL
        )
    }
}

private extension VideoGenerationStatus {
    init(_ dto: PixVerseStatusDTO) throws {
        switch dto.status {
        case "success":
            guard let videoURL = dto.videoURL.flatMap(URL.init(string:)) else { throw APIError.invalidResponse }
            self = .succeeded(videoURL: videoURL)
        case "error":
            self = .failed
        default:
            // Спека называет только `generating`; любое другое промежуточное состояние опрашиваем так же.
            self = .generating
        }
    }
}
