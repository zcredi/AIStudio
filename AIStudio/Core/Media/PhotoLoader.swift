import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PhotoLoaderError: Error, Equatable, Sendable {
    case unreadableImage
}

/// Выбранное фото, уже уменьшенное: JPEG для загрузки и маленький JPEG для миниатюры.
struct LoadedPhoto: Equatable, Sendable {
    let jpegData: Data
    let thumbnailData: Data
}

/// Загружает фото из результатов `PHPickerViewController`. Исходный файл читается через ImageIO,
/// поэтому полноразмерный битмап никогда не лежит в памяти.
enum PhotoLoader {
    // MARK: - Types

    private enum Size {
        /// Длинная сторона для загрузки: хватает на 1080p после кропа под любой формат.
        static let maxPixelSize = 2560
        static let thumbnailPixelSize = 300
        static let compressionQuality = 0.9
    }

    // MARK: - API

    /// Вызывается на главном акторе, которому принадлежит provider пикера. Здесь только стартует запрос:
    /// файл декодируется в фоновом колбэке provider'а.
    @MainActor
    static func load(from provider: NSItemProvider) async throws -> LoadedPhoto {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                // Файл удаляется, как только этот обработчик вернёт управление, поэтому читаем его прямо здесь.
                guard let url else {
                    continuation.resume(throwing: error ?? PhotoLoaderError.unreadableImage)
                    return
                }
                continuation.resume(with: Result { try makePhoto(from: url) })
            }
        }
    }

    // MARK: - Private

    private static func makePhoto(from url: URL) throws -> LoadedPhoto {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            throw PhotoLoaderError.unreadableImage
        }
        return LoadedPhoto(
            jpegData: try jpegData(from: source, maxPixelSize: Size.maxPixelSize),
            thumbnailData: try jpegData(from: source, maxPixelSize: Size.thumbnailPixelSize)
        )
    }

    private static func jpegData(from source: CGImageSource, maxPixelSize: Int) throws -> Data {
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            // Учитывает EXIF-ориентацию, чтобы фото выглядело так же, как в «Фото».
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary
        let data = NSMutableData()
        guard
            let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options),
            let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
        else {
            throw PhotoLoaderError.unreadableImage
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: Size.compressionQuality] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw PhotoLoaderError.unreadableImage }
        return data as Data
    }
}
