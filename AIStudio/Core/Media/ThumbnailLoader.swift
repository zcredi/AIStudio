import CoreImage
import ImageIO
import UIKit

/// Декодирует локальные изображения в маленькие битмапы вне главного актора и держит недавние в памяти.
@MainActor
final class ThumbnailLoader {
    // MARK: - Properties

    /// Один контекст переиспользуется, потому что создавать его дорого.
    private nonisolated static let context = CIContext()
    private let cache = NSCache<NSString, UIImage>()

    // MARK: - Init

    init(countLimit: Int) {
        cache.countLimit = countLimit
    }

    // MARK: - API

    /// `blurRadius` задаётся в пикселях результата; ноль оставляет изображение резким.
    func thumbnail(for fileURL: URL, maxPixelSize: Int, blurRadius: CGFloat = 0) async -> UIImage? {
        let key = "\(fileURL.path(percentEncoded: false))|\(maxPixelSize)|\(blurRadius)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let image = await Self.decode(fileURL, maxPixelSize: maxPixelSize, blurRadius: blurRadius) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    // MARK: - Private

    @concurrent
    private static func decode(_ fileURL: URL, maxPixelSize: Int, blurRadius: CGFloat) async -> UIImage? {
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as CFDictionary
        guard
            let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
            let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options)
        else {
            return nil
        }
        guard blurRadius > 0 else { return UIImage(cgImage: image) }

        let input = CIImage(cgImage: image)
        // Clamping не даёт краям растворяться в прозрачность.
        let blurred = input.clampedToExtent().applyingGaussianBlur(sigma: blurRadius).cropped(to: input.extent)
        return context.createCGImage(blurred, from: input.extent).map { UIImage(cgImage: $0) }
    }
}
