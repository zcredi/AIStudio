protocol ChatLocalStateRepository: Sendable {
    func load() async -> ChatLocalState
    func save(_ state: ChatLocalState) async throws
}
