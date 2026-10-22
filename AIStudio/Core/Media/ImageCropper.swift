import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageCropperError: Error, Equatable, Sendable {
    case unreadableImage
    case encodingFailed
}

/// Обрезает закодированные изображения через ImageIO, не декодируя полноразмерный битмап.
enum ImageCropper {
    /// Возвращает JPEG самой большой центральной области с `aspectRatio` (ширина / высота).
    /// Сначала изображение уменьшается так, чтобы длинная сторона была не больше `maxPixelSize`.
    @concurrent
    static func jpegData(from data: Data, croppedTo aspectRatio: Double, maxPixelSize: Int) async throws -> Data {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateThumbnailAtIndex(source, 0, downsamplingOptions(maxPixelSize: maxPixelSize))
        else {
            throw ImageCropperError.unreadableImage
        }
        let cropRect = centeredRect(in: CGSize(width: image.width, height: image.height), aspectRatio: aspectRatio)
        guard let cropped = image.cropping(to: cropRect) else { throw ImageCropperError.unreadableImage }
        return try jpegData(from: cropped)
    }

    static func centeredRect(in size: CGSize, aspectRatio: Double) -> CGRect {
        let exactSize = size.width / size.height > aspectRatio
            ? CGSize(width: size.height * aspectRatio, height: size.height)
            : CGSize(width: size.width, height: size.width / aspectRatio)
        // Округление вниз держит прямоугольник внутри изображения; при увеличении изменились бы пропорции.
        let cropSize = CGSize(width: exactSize.width.rounded(.down), height: exactSize.height.rounded(.down))
        let origin = CGPoint(
            x: ((size.width - cropSize.width) / 2).rounded(.down),
            y: ((size.height - cropSize.height) / 2).rounded(.down)
        )
        return CGRect(origin: origin, size: cropSize)
    }

    // MARK: - Private

    private static func downsamplingOptions(maxPixelSize: Int) -> CFDictionary {
        [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            // Учитывает EXIF-ориентацию, чтобы кроп совпадал с тем, что видел пользователь.
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary
    }

    private static func jpegData(from image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw ImageCropperError.encodingFailed
        }
        let options = [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary
        CGImageDestinationAddImage(destination, image, options)
        guard CGImageDestinationFinalize(destination) else { throw ImageCropperError.encodingFailed }
        return data as Data
    }
}
