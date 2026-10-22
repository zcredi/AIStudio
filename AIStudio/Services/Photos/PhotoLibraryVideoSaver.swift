import OSLog
import Photos

struct PhotoLibraryVideoSaver: VideoSaving {
    private let logger = Logger(category: "PhotoLibraryVideoSaver")

    func saveVideo(at fileURL: URL) async throws {
        // Для сохранения нужен только доступ на добавление; система спросит его при первом сохранении.
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw VideoSavingError.accessDenied }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.forAsset().addResource(with: .video, fileURL: fileURL, options: nil)
            }
        } catch {
            logger.error("Failed to save video: \(error)")
            throw VideoSavingError.failed
        }
    }
}
