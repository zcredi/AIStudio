import Foundation

/// Генерации и их файлы на устройстве. Файлы адресуются по ID генерации.
protocol VideoLibraryRepository: Sendable {
    func generations() async -> [VideoGeneration]
    func save(_ generations: [VideoGeneration]) async throws
    func saveStartFrame(_ jpegData: Data, for id: UUID) async throws
    func startFrame(for id: UUID) async throws -> Data
    /// Скачивает результат в библиотеку: ссылка на сервере истекает.
    func downloadVideo(from remoteURL: URL, for id: UUID) async throws
    func startFrameURL(for id: UUID) -> URL
    func videoURL(for id: UUID) -> URL
}
