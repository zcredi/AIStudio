import Foundation
@testable import AIStudio

actor FakeVideoSaver: VideoSaving {
    private(set) var savedURLs: [URL] = []
    private let error: VideoSavingError?

    init(error: VideoSavingError? = nil) {
        self.error = error
    }

    func saveVideo(at fileURL: URL) async throws {
        if let error {
            throw error
        }
        savedURLs.append(fileURL)
    }
}
