import Combine
import Foundation
@testable import AIStudio

@MainActor
final class FakeVideoGenerator: VideoGenerating {
    // MARK: - Properties

    var generationsPublisher: AnyPublisher<[VideoGeneration], Never> {
        generationsSubject.eraseToAnyPublisher()
    }

    var generateError: (any Error)?
    private(set) var requests: [VideoGenerationRequest] = []
    private(set) var retriedIDs: [VideoGeneration.ID] = []
    private(set) var seenIDs: [VideoGeneration.ID] = []

    let generationsSubject: CurrentValueSubject<[VideoGeneration], Never>
    private let generatedID = UUID()

    // MARK: - Init

    init(generations: [VideoGeneration] = []) {
        generationsSubject = CurrentValueSubject(generations)
    }

    // MARK: - API

    func send(_ generations: [VideoGeneration]) {
        generationsSubject.send(generations)
    }

    // MARK: - VideoGenerating

    func generate(_ request: VideoGenerationRequest) async throws -> VideoGeneration.ID {
        requests.append(request)
        if let generateError {
            throw generateError
        }
        return generatedID
    }

    func retry(_ id: VideoGeneration.ID) {
        retriedIDs.append(id)
    }

    func markSeen(_ id: VideoGeneration.ID) {
        seenIDs.append(id)
    }

    func videoURL(for id: VideoGeneration.ID) -> URL {
        URL(filePath: "/library/\(id.uuidString).mp4")
    }

    func startFrameURL(for id: VideoGeneration.ID) -> URL {
        URL(filePath: "/library/\(id.uuidString).jpg")
    }
}
