@testable import AIStudio

actor FakeChatLocalStateRepository: ChatLocalStateRepository {
    private(set) var state: ChatLocalState

    init(state: ChatLocalState = ChatLocalState()) {
        self.state = state
    }

    func load() async -> ChatLocalState {
        state
    }

    func save(_ state: ChatLocalState) async throws {
        self.state = state
    }
}
