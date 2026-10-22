import Photos

struct PhotoLibraryAccessProvider: PhotoLibraryAccessProviding {
    func currentAccess() -> PhotoLibraryAccess {
        PhotoLibraryAccess(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestAccess() async -> PhotoLibraryAccess {
        PhotoLibraryAccess(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
    }
}

// MARK: - Mapping

private extension PhotoLibraryAccess {
    init(_ status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorized, .limited:
            self = .granted
        case .denied, .restricted:
            self = .denied
        @unknown default:
            self = .denied
        }
    }
}
