import OSLog

struct FileChatLocalStateRepository: ChatLocalStateRepository {
    // MARK: - Properties

    private let store: CodableFileStore<ChatLocalState>
    private let logger = Logger(category: "FileChatLocalStateRepository")

    // MARK: - Init

    init(store: CodableFileStore<ChatLocalState>) {
        self.store = store
    }

    // MARK: - ChatLocalStateRepository

    /// Если файла нет или он не читается, значит, ни один чат ещё не закрепляли и не удаляли.
    func load() async -> ChatLocalState {
        do {
            return try await store.load() ?? ChatLocalState()
        } catch {
            logger.error("Failed to read chat state: \(error)")
            return ChatLocalState()
        }
    }

    func save(_ state: ChatLocalState) async throws {
        try await store.save(state)
    }
}
