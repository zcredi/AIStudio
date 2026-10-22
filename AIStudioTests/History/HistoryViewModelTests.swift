import XCTest
@testable import AIStudio

@MainActor
final class HistoryViewModelTests: XCTestCase {
    private let chat = Chat(id: "chat-1", title: "Sandbox chat", updatedAt: Date(), lastMessagePreview: "Hello")

    func test_load_withChats_showsThemGrouped() async {
        let viewModel = makeViewModel(chats: .success([chat]))

        await viewModel.load().value

        XCTAssertEqual(viewModel.state.chats.value?.flatMap(\.rows).map(\.title), ["Sandbox chat"])
    }

    func test_load_whenRequestFails_showsError() async throws {
        let viewModel = makeViewModel(chats: .failure(APIError.offline))

        await viewModel.load().value

        let expected = try XCTUnwrap(UserFacingError(APIError.offline))
        XCTAssertEqual(viewModel.state.chats, .failed(expected))
    }

    func test_load_withoutChats_showsEmptyList() async {
        let viewModel = makeViewModel(chats: .success([]))

        await viewModel.load().value

        XCTAssertEqual(viewModel.state.chats, .loaded([]))
    }

    func test_renameChat_updatesTitleAndSavesIt() async {
        // Дано
        let localState = FakeChatLocalStateRepository()
        let viewModel = makeViewModel(chats: .success([chat]), localState: localState)
        await viewModel.load().value

        // Когда
        viewModel.renameChat(id: chat.id, to: "  Welcome email ")

        // Тогда
        XCTAssertEqual(viewModel.state.chats.value?.first?.rows.first?.title, "Welcome email")
        await viewModel.load().value
        let savedTitles = await localState.state.customTitles
        XCTAssertEqual(savedTitles, ["chat-1": "Welcome email"])
    }

    func test_renameChat_withBlankTitle_keepsOldTitle() async {
        let viewModel = makeViewModel(chats: .success([chat]))
        await viewModel.load().value

        viewModel.renameChat(id: chat.id, to: "   ")

        XCTAssertEqual(viewModel.state.chats.value?.first?.rows.first?.title, "Sandbox chat")
    }

    func test_deleteChat_removesItFromList() async {
        let viewModel = makeViewModel(chats: .success([chat]))
        await viewModel.load().value

        viewModel.deleteChat(id: chat.id)

        XCTAssertEqual(viewModel.state.chats, .loaded([]))
    }

    func test_selectChat_opensIt() async {
        // Дано
        let viewModel = makeViewModel(chats: .success([chat]))
        let events = PublisherRecorder(viewModel.events)
        await viewModel.load().value

        // Когда
        viewModel.selectChat(id: chat.id)

        // Тогда
        XCTAssertEqual(events.values, [.openChat(chat)])
    }

    // MARK: - Videos

    func test_videos_followGeneratorNewestFirst() {
        // Дано
        let newer = VideoGeneration.fixture(format: .landscape, state: .ready, isNew: true)
        let older = VideoGeneration.fixture(state: .inProgress)
        let generator = FakeVideoGenerator(generations: [newer, older])

        // Когда
        let viewModel = makeViewModel(chats: .success([]), generator: generator)

        // Тогда
        XCTAssertEqual(viewModel.state.videos.map(\.id), [newer.id, older.id])
        XCTAssertEqual(viewModel.state.videos.first?.aspectRatio, VideoFormat.landscape.aspectRatio)
        XCTAssertEqual(viewModel.state.videos.first?.videoURL, generator.videoURL(for: newer.id))
    }

    func test_selectVideo_opensResultOrGeneratingScreen() {
        // Дано
        let ready = VideoGeneration.fixture(state: .ready)
        let inProgress = VideoGeneration.fixture(state: .inProgress)
        let failed = VideoGeneration.fixture(state: .failed)
        let generator = FakeVideoGenerator(generations: [ready, inProgress, failed])
        let viewModel = makeViewModel(chats: .success([]), generator: generator)
        let events = PublisherRecorder(viewModel.events)

        // Когда
        [ready, inProgress, failed].forEach { viewModel.selectVideo(id: $0.id) }

        // Тогда
        XCTAssertEqual(events.values, [.openVideo(ready), .openGeneration(inProgress.id)])
    }

    func test_retryVideo_restartsGeneration() {
        let failed = VideoGeneration.fixture(state: .failed)
        let generator = FakeVideoGenerator(generations: [failed])
        let viewModel = makeViewModel(chats: .success([]), generator: generator)

        viewModel.retryVideo(id: failed.id)

        XCTAssertEqual(generator.retriedIDs, [failed.id])
    }

    func test_retryVideo_forFreeUser_showsPaywall() {
        let failed = VideoGeneration.fixture(state: .failed)
        let generator = FakeVideoGenerator(generations: [failed])
        let gate = FakePremiumGate()
        gate.isPremium = false
        let viewModel = makeViewModel(chats: .success([]), generator: generator, premiumGate: gate)

        viewModel.retryVideo(id: failed.id)

        XCTAssertTrue(generator.retriedIDs.isEmpty)
        XCTAssertEqual(gate.paywallRequestCount, 1)
    }

    func test_isValidTitle_rejectsWhitespace() {
        XCTAssertFalse(HistoryViewModel.isValidTitle(" \n "))
        XCTAssertTrue(HistoryViewModel.isValidTitle("Plan"))
    }

    // MARK: - Private

    private func makeViewModel(
        chats: Result<[Chat], any Error>,
        localState: FakeChatLocalStateRepository = FakeChatLocalStateRepository(),
        generator: FakeVideoGenerator = FakeVideoGenerator(),
        premiumGate: FakePremiumGate = FakePremiumGate()
    ) -> HistoryViewModel {
        HistoryViewModel(
            chatRepository: FakeChatRepository(chats: chats),
            localStateRepository: localState,
            generator: generator,
            premiumGate: premiumGate
        )
    }
}
