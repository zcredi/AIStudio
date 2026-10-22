import Combine
import XCTest
@testable import AIStudio

@MainActor
final class ChatViewModelTests: XCTestCase {
    private struct SUT {
        let viewModel: ChatViewModel
        let repository: FakeChatRepository
        let localState: FakeChatLocalStateRepository
        let premiumGate: FakePremiumGate
        let copier: FakeTextCopier
        let events: PublisherRecorder<ChatViewModel.Event>
    }

    private let existingChat = Chat(id: "chat-1", title: "Welcome email", updatedAt: Date(timeIntervalSince1970: 0), lastMessagePreview: nil)

    // MARK: - Sending

    func test_sendTapped_withDraft_showsPromptAndReply() async {
        // Дано
        let sut = makeSUT()
        sut.viewModel.updateDraft("Hi")

        // Когда
        sut.viewModel.sendTapped()
        await waitUntil(sut.viewModel) { !$0.isGenerating }

        // Тогда
        XCTAssertEqual(texts(of: sut.viewModel.state.items), ["Hi", "Hello!"])
        XCTAssertEqual(sut.viewModel.state.draft, "")
    }

    func test_sendTapped_showsTypingAndBlocksSending() {
        let sut = makeSUT()
        sut.viewModel.updateDraft("Hi")

        sut.viewModel.sendTapped()

        XCTAssertEqual(sut.viewModel.state.items.last, .typing)
        sut.viewModel.updateDraft("Next question")
        XCTAssertFalse(sut.viewModel.state.canSend)
    }

    func test_sendTapped_withoutSubscription_opensPaywallAndKeepsDraft() async {
        // Дано
        let sut = makeSUT()
        sut.premiumGate.isPremium = false
        sut.viewModel.updateDraft("Hi")

        // Когда
        sut.viewModel.sendTapped()

        // Тогда
        XCTAssertEqual(sut.premiumGate.paywallRequestCount, 1)
        XCTAssertEqual(sut.viewModel.state.draft, "Hi")
        let sentMessages = await sut.repository.sentMessages
        XCTAssertTrue(sentMessages.isEmpty)
    }

    func test_sendTapped_withBlankDraft_doesNothing() async {
        let sut = makeSUT()
        sut.viewModel.updateDraft("   \n")

        sut.viewModel.sendTapped()

        XCTAssertEqual(sut.viewModel.state.items, [])
        XCTAssertEqual(sut.premiumGate.paywallRequestCount, 0)
    }

    func test_reply_withServerChatID_sendsNextMessageToIt() async {
        // Дано
        let sut = makeSUT(repository: FakeChatRepository(replyChatID: "server-chat"))
        sut.viewModel.updateDraft("Hi")
        sut.viewModel.sendTapped()
        await waitUntil(sut.viewModel) { !$0.isGenerating }

        // Когда
        sut.viewModel.updateDraft("And now?")
        sut.viewModel.sendTapped()
        await waitUntil(sut.viewModel) { !$0.isGenerating }

        // Тогда
        let chatIDs = await sut.repository.sentMessages.map(\.chatID)
        XCTAssertEqual(chatIDs.last, "server-chat")
    }

    func test_applySuggestion_fillsDraftWithoutSending() async {
        let sut = makeSUT()

        sut.viewModel.applySuggestion("Plan my day")

        XCTAssertEqual(sut.viewModel.state.draft, "Plan my day")
        let sentMessages = await sut.repository.sentMessages
        XCTAssertTrue(sentMessages.isEmpty)
    }

    // MARK: - Regenerate and failures

    func test_regenerateTapped_replacesLastReplyWithoutNewPrompt() async {
        // Дано
        let sut = makeSUT()
        sut.viewModel.updateDraft("Hi")
        sut.viewModel.sendTapped()
        await waitUntil(sut.viewModel) { !$0.isGenerating }
        await sut.repository.setReply(.success("Another answer"))

        // Когда
        sut.viewModel.regenerateTapped()
        await waitUntil(sut.viewModel) { !$0.isGenerating }

        // Тогда
        XCTAssertEqual(texts(of: sut.viewModel.state.items), ["Hi", "Another answer"])
        let prompts = await sut.repository.sentMessages.map(\.text)
        XCTAssertEqual(prompts, ["Hi", "Hi"])
    }

    func test_onlyLastReply_canBeRegenerated() async {
        // Дано
        let sut = makeSUT()

        // Когда
        for prompt in ["First", "Second"] {
            sut.viewModel.updateDraft(prompt)
            sut.viewModel.sendTapped()
            await waitUntil(sut.viewModel) { !$0.isGenerating }
        }

        // Тогда
        let regenerateFlags = sut.viewModel.state.items.compactMap { item -> Bool? in
            guard case .message(let message, let canRegenerate) = item, message.role == .assistant else { return nil }
            return canRegenerate
        }
        XCTAssertEqual(regenerateFlags, [false, true])
    }

    func test_send_whenRequestFails_showsRetryableFailure() async throws {
        // Дано
        let sut = makeSUT(repository: FakeChatRepository(reply: .failure(APIError.offline)))
        sut.viewModel.updateDraft("Hi")

        // Когда
        sut.viewModel.sendTapped()
        await waitUntil(sut.viewModel) { !$0.isGenerating }

        // Тогда
        let expected = try XCTUnwrap(UserFacingError(APIError.offline))
        XCTAssertEqual(sut.viewModel.state.items.last, .failure(expected))
    }

    func test_retryTapped_afterFailure_showsReply() async {
        // Дано
        let sut = makeSUT(repository: FakeChatRepository(reply: .failure(APIError.timeout)))
        sut.viewModel.updateDraft("Hi")
        sut.viewModel.sendTapped()
        await waitUntil(sut.viewModel) { !$0.isGenerating }
        await sut.repository.setReply(.success("Hello!"))

        // Когда
        sut.viewModel.retryTapped()
        await waitUntil(sut.viewModel) { !$0.isGenerating }

        // Тогда
        XCTAssertEqual(texts(of: sut.viewModel.state.items), ["Hi", "Hello!"])
    }

    // MARK: - Copy

    func test_copyMessage_whenCopied_showsCopiedToast() async {
        let sut = await makeSUTWithReply()

        sut.viewModel.copyMessage(id: lastMessageID(in: sut.viewModel))

        XCTAssertEqual(sut.copier.copiedTexts, ["Hello!"])
        XCTAssertEqual(sut.events.values, [.showToast(.copied)])
    }

    func test_copyMessage_whenClipboardFails_showsFailureToast() async {
        let sut = await makeSUTWithReply()
        sut.copier.isAvailable = false

        sut.viewModel.copyMessage(id: lastMessageID(in: sut.viewModel))

        XCTAssertEqual(sut.events.values, [.showToast(.copyFailed)])
    }

    // MARK: - History and chat actions

    func test_load_existingChat_showsHistory() async {
        // Дано
        let history = [
            ChatMessage(id: "1", role: .user, text: "Hi", createdAt: Date()),
            ChatMessage(id: "2", role: .assistant, text: "Hello!", createdAt: Date()),
        ]
        let sut = makeSUT(chat: existingChat, repository: FakeChatRepository(history: history))

        // Когда
        await sut.viewModel.load().value

        // Тогда
        XCTAssertEqual(texts(of: sut.viewModel.state.items), ["Hi", "Hello!"])
        XCTAssertEqual(sut.viewModel.state.history, .loaded(history))
    }

    func test_load_pinnedChat_showsPin() async {
        let localState = FakeChatLocalStateRepository(state: ChatLocalState(pinnedChatIDs: ["chat-1"]))
        let sut = makeSUT(chat: existingChat, localState: localState)

        await sut.viewModel.load().value

        XCTAssertTrue(sut.viewModel.state.isPinned)
    }

    func test_togglePinTapped_savesPin() async {
        let sut = makeSUT(chat: existingChat)

        sut.viewModel.togglePinTapped()

        XCTAssertTrue(sut.viewModel.state.isPinned)
        let isSaved = await eventually { await sut.localState.state.pinnedChatIDs == ["chat-1"] }
        XCTAssertTrue(isSaved)
    }

    func test_deletionConfirmed_hidesChatAndLeaves() async {
        let sut = makeSUT(chat: existingChat)

        sut.viewModel.deletionConfirmed()

        XCTAssertEqual(sut.events.values, [.deleted])
        let isSaved = await eventually { await sut.localState.state.deletedChatIDs == ["chat-1"] }
        XCTAssertTrue(isSaved)
    }

    func test_shareTapped_sharesTranscript() async {
        let sut = await makeSUTWithReply()

        sut.viewModel.shareTapped()

        XCTAssertEqual(sut.events.values, [.share("You:\nHi\n\nAI Chat:\nHello!")])
    }

    // MARK: - Private

    private func makeSUT(
        chat: Chat? = nil,
        repository: FakeChatRepository = FakeChatRepository(),
        localState: FakeChatLocalStateRepository = FakeChatLocalStateRepository()
    ) -> SUT {
        let premiumGate = FakePremiumGate()
        let copier = FakeTextCopier()
        let viewModel = ChatViewModel(
            chat: chat,
            chatRepository: repository,
            localStateRepository: localState,
            premiumGate: premiumGate,
            textCopier: copier
        )
        return SUT(
            viewModel: viewModel,
            repository: repository,
            localState: localState,
            premiumGate: premiumGate,
            copier: copier,
            events: PublisherRecorder(viewModel.events)
        )
    }

    private func makeSUTWithReply() async -> SUT {
        let sut = makeSUT()
        sut.viewModel.updateDraft("Hi")
        sut.viewModel.sendTapped()
        await waitUntil(sut.viewModel) { !$0.isGenerating }
        return sut
    }

    private func texts(of items: [ChatItem]) -> [String] {
        items.compactMap { item in
            guard case .message(let message, _) = item else { return nil }
            return message.text
        }
    }

    private func lastMessageID(in viewModel: ChatViewModel) -> ChatMessage.ID {
        guard case .message(let message, _) = viewModel.state.items.last else { return "" }
        return message.id
    }

    private func waitUntil(_ viewModel: ChatViewModel, _ condition: @escaping (ChatViewModel.State) -> Bool) async {
        let expectation = expectation(description: "Chat state")
        let cancellable = viewModel.$state.first(where: condition).sink { _ in expectation.fulfill() }
        await fulfillment(of: [expectation], timeout: 1)
        cancellable.cancel()
    }

    /// Даёт фоновой работе, например сохранению локальных флагов, закончиться без sleep.
    private func eventually(_ condition: () async -> Bool) async -> Bool {
        for _ in 0..<100 {
            if await condition() {
                return true
            }
            await Task.yield()
        }
        return false
    }
}
