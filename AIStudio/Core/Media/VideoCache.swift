import CryptoKit
import Foundation

/// Скачивает видео в Caches и возвращает локальные файлы. Превью маленькие и не меняются,
/// поэтому файл играет без повторной буферизации каждый раз, когда ячейка возвращается на экран.
actor VideoCache {
    // MARK: - Properties

    private let directory: URL
    private let session: URLSession
    private var downloads: [URL: Task<URL, any Error>] = [:]

    // MARK: - Init

    init(
        directory: URL = URL.cachesDirectory.appending(path: "Videos", directoryHint: .isDirectory),
        session: URLSession = .shared
    ) {
        self.directory = directory
        self.session = session
    }

    // MARK: - API

    /// Для локальных файлов возвращает сам `url`. Параллельные запросы одного URL делят одну загрузку.
    func localURL(for url: URL) async throws -> URL {
        guard !url.isFileURL else { return url }

        let destination = directory.appending(path: Self.fileName(for: url))
        if FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)) {
            return destination
        }
        if let download = downloads[url] {
            return try await download.value
        }

        let download = Task { [session, directory] in
            try await Self.download(url, to: destination, in: directory, session: session)
        }
        downloads[url] = download
        defer { downloads[url] = nil }
        return try await download.value
    }

    // MARK: - Private

    private static func fileName(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return "\(name).\(url.pathExtension.isEmpty ? "mp4" : url.pathExtension)"
    }

    @concurrent
    private static func download(_ url: URL, to destination: URL, in directory: URL, session: URLSession) async throws -> URL {
        let (temporaryURL, response) = try await session.download(from: url)
        if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
            throw URLError(.badServerResponse)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Другой запрос мог уже сохранить этот же файл.
        if FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        return destination
    }
}
