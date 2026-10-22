import Foundation
import OSLog

/// Хранит историю в JSON-файле, а кадры и видео рядом в Application Support,
/// поэтому очистка кэша никогда не удаляет видео пользователя.
struct FileVideoLibraryRepository: VideoLibraryRepository {
    // MARK: - Properties

    private let store: CodableFileStore<[VideoGeneration]>
    private let directory: URL
    private let session: URLSession
    private let logger = Logger(category: "FileVideoLibraryRepository")

    // MARK: - Init

    init(
        store: CodableFileStore<[VideoGeneration]>,
        directory: URL = URL.applicationSupportDirectory.appending(path: "Videos", directoryHint: .isDirectory),
        session: URLSession = .shared
    ) {
        self.store = store
        self.directory = directory
        self.session = session
    }

    // MARK: - VideoLibraryRepository

    /// Если файла нет или он не читается, значит, ещё ничего не генерировали.
    func generations() async -> [VideoGeneration] {
        do {
            return try await store.load() ?? []
        } catch {
            logger.error("Failed to read video history: \(error)")
            return []
        }
    }

    func save(_ generations: [VideoGeneration]) async throws {
        try await store.save(generations)
    }

    @concurrent
    func saveStartFrame(_ jpegData: Data, for id: UUID) async throws {
        try createDirectory()
        try jpegData.write(to: startFrameURL(for: id), options: .atomic)
    }

    @concurrent
    func startFrame(for id: UUID) async throws -> Data {
        try Data(contentsOf: startFrameURL(for: id))
    }

    @concurrent
    func downloadVideo(from remoteURL: URL, for id: UUID) async throws {
        let (temporaryURL, response) = try await download(remoteURL)
        if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
            throw APIError(statusCode: response.statusCode, message: nil)
        }
        try createDirectory()
        let destination = videoURL(for: id)
        if FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
    }

    func startFrameURL(for id: UUID) -> URL {
        directory.appending(path: "\(id.uuidString).jpg")
    }

    func videoURL(for id: UUID) -> URL {
        directory.appending(path: "\(id.uuidString).mp4")
    }

    // MARK: - Private

    private func createDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Сводит `URLError` к ошибкам так же, как `APIClient`, чтобы вызывающему коду хватало одного типа ошибок.
    private func download(_ url: URL) async throws -> (URL, URLResponse) {
        do {
            return try await session.download(from: url)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError {
            throw APIError(error)
        }
    }
}
