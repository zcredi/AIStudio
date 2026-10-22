import Foundation

/// Хранит одно `Codable`-значение в JSON-файле в Application Support. Файловый ввод-вывод идёт вне главного актора.
actor CodableFileStore<Value: Codable & Sendable> {
    // MARK: - Properties

    private let fileURL: URL

    // MARK: - Init

    /// `fileName` задаётся относительно Application Support: абсолютный путь меняется между установками.
    init(fileName: String) {
        fileURL = URL.applicationSupportDirectory.appending(path: fileName)
    }

    // MARK: - API

    /// Возвращает `nil`, если ещё ничего не сохраняли.
    func load() throws -> Value? {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Value.self, from: data)
    }

    func save(_ value: Value) throws {
        let data = try JSONEncoder().encode(value)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}
