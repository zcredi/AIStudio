import Foundation
@testable import AIStudio

extension VideoGeneration {
    static func fixture(
        id: UUID = UUID(),
        format: VideoFormat = .portrait,
        state: State = .ready,
        isNew: Bool = false,
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) -> VideoGeneration {
        VideoGeneration(
            id: id,
            templateID: 1,
            templateName: "Snowfall",
            format: format,
            quality: .p720,
            createdAt: createdAt,
            state: state,
            remoteID: nil,
            isNew: isNew
        )
    }
}
