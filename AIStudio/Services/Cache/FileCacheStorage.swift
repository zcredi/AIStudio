import Foundation
import OSLog

/// Папка Caches и общий URL-кэш. Пользовательские данные в Application Support не трогаются.
struct FileCacheStorage: CacheClearing {
    // MARK: - Properties

    private let urlCache: URLCache
    private let logger = Logger(category: "FileCacheStorage")

    // MARK: - Init

    init(urlCache: URLCache = .shared) {
        self.urlCache = urlCache
    }

    // MARK: - CacheClearing

    @concurrent
    func cacheSize() async -> Int64 {
        let files = cachedFiles().reduce(Int64(0)) { total, url in
            // Файл, исчезнувший во время подсчёта, просто не попадает в сумму.
            let size = (try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize) ?? 0
            return total + Int64(size)
        }
        return files + Int64(urlCache.currentDiskUsage)
    }

    @concurrent
    func clearCache() async {
        urlCache.removeAllCachedResponses()
        // Если папки Caches нет, чистить нечего.
        let items = (try? FileManager.default.contentsOfDirectory(at: URL.cachesDirectory, includingPropertiesForKeys: nil)) ?? []
        for item in items {
            do {
                try FileManager.default.removeItem(at: item)
            } catch {
                // Файлы, которые держит система, остаются; остальной кэш всё равно очищается.
                logger.error("Failed to remove cache item: \(error)")
            }
        }
    }

    // MARK: - Private

    private func cachedFiles() -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: URL.cachesDirectory,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey]
        ) else {
            return []
        }
        return enumerator.compactMap { $0 as? URL }
    }
}
