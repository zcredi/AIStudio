import Foundation
@testable import AIStudio

actor FakeVideoGenerationRepository: VideoGenerationRepository {
    // MARK: - Properties

    private(set) var startCount = 0
    private(set) var uploadedImages: [Data] = []
    private(set) var polledIDs: [Int] = []

    private let remoteID: Int
    private var startError: (any Error)?
    /// Проигрываются по одному на каждую проверку статуса; последний повторяется.
    private var statuses: [VideoGenerationStatus]

    // MARK: - Init

    init(remoteID: Int = 42, statuses: [VideoGenerationStatus]) {
        self.remoteID = remoteID
        self.statuses = statuses
    }

    // MARK: - API

    func setStatuses(_ statuses: [VideoGenerationStatus]) {
        self.statuses = statuses
    }

    func setStartError(_ error: (any Error)?) {
        startError = error
    }

    // MARK: - VideoGenerationRepository

    func startGeneration(templateID: Int, image: Data, quality: VideoQuality) async throws -> Int {
        startCount += 1
        if let startError {
            throw startError
        }
        uploadedImages.append(image)
        return remoteID
    }

    func status(ofGeneration id: Int) async throws -> VideoGenerationStatus {
        polledIDs.append(id)
        guard statuses.count > 1 else { return statuses.first ?? .generating }
        return statuses.removeFirst()
    }
}
