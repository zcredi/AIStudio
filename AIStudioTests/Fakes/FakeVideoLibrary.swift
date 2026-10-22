import Foundation
@testable import AIStudio

actor FakeVideoLibrary: VideoLibraryRepository {
    // MARK: - Properties

    private(set) var savedGenerations: [VideoGeneration] = []
    private(set) var startFrames: [UUID: Data] = [:]
    private(set) var downloads: [UUID: URL] = [:]

    private let storedGenerations: [VideoGeneration]

    // MARK: - Init

    init(generations: [VideoGeneration] = [], startFrames: [UUID: Data] = [:]) {
        storedGenerations = generations
        self.startFrames = startFrames
    }

    // MARK: - VideoLibraryRepository

    func generations() async -> [VideoGeneration] {
        storedGenerations
    }

    func save(_ generations: [VideoGeneration]) async throws {
        savedGenerations = generations
    }

    func saveStartFrame(_ jpegData: Data, for id: UUID) async throws {
        startFrames[id] = jpegData
    }

    func startFrame(for id: UUID) async throws -> Data {
        guard let frame = startFrames[id] else { throw CocoaError(.fileNoSuchFile) }
        return frame
    }

    func downloadVideo(from remoteURL: URL, for id: UUID) async throws {
        downloads[id] = remoteURL
    }

    nonisolated func startFrameURL(for id: UUID) -> URL {
        URL(filePath: "/library/\(id.uuidString).jpg")
    }

    nonisolated func videoURL(for id: UUID) -> URL {
        URL(filePath: "/library/\(id.uuidString).mp4")
    }
}
