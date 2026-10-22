import Foundation

protocol VideoGenerationRepository: Sendable {
    /// Загружает стартовый кадр (JPEG) и возвращает ID для `status(ofGeneration:)`.
    func startGeneration(templateID: Int, image: Data, quality: VideoQuality) async throws -> Int
    func status(ofGeneration id: Int) async throws -> VideoGenerationStatus
}
