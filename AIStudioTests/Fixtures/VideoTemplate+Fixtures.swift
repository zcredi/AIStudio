import Foundation
@testable import AIStudio

extension VideoTemplate {
    static func fixture(
        id: Int = 1,
        name: String = "Snowfall",
        category: String = "Trending",
        qualities: [VideoQuality] = VideoQuality.allCases
    ) -> VideoTemplate {
        let previewURL = URL(filePath: "/previews/\(id).mp4")
        return VideoTemplate(
            id: id,
            name: name,
            category: category,
            qualities: qualities,
            previewURL: previewURL,
            largePreviewURL: previewURL
        )
    }
}
