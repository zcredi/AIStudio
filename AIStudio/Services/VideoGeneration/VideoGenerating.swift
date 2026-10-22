import Combine
import Foundation

@MainActor
protocol VideoGenerating: AnyObject {
    /// Все генерации, от новых к старым.
    var generationsPublisher: AnyPublisher<[VideoGeneration], Never> { get }

    /// Добавляет генерацию в историю и возвращает её ID; прогресс приходит через `generationsPublisher`.
    /// Бросает, только если фото не удалось подготовить.
    func generate(_ request: VideoGenerationRequest) async throws -> VideoGeneration.ID
    func retry(_ id: VideoGeneration.ID)
    func markSeen(_ id: VideoGeneration.ID)
    func videoURL(for id: VideoGeneration.ID) -> URL
    func startFrameURL(for id: VideoGeneration.ID) -> URL
}
