import Combine
import Foundation

@MainActor
final class ChatViewModel {
    // MARK: - Types

    struct State: Equatable {
        var date: Date
        var isPinned = false
        var history: Loadable<[ChatMessage]>
        var items: [ChatItem] = []
        var draft = ""
        var isGenerating = false

        /// Во время генерации поле ввода остаётся редактируемым, ждёт только отправка.
        /// Существующий чат ещё и ждёт свою историю, иначе она заменила бы новое сообщение.
        var canSend: Bool {
            guard case .loaded = history, !isGenerating else { return false }
            return !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        /// Поделиться, закрепить и удалить можно только переписку, которая уже есть на сервере.
        var hasConversation: Bool {
            items.contains { if case .message = $0 { true } else { false } }
        }
    }

    enum Toast: Equatable {
        case copied
        case copyFailed
    }

    enum Event: Equatable {
        case showToast(Toast)
        case share(String)
        case confirmDeletion
        case deleted
    }

    // MARK: - Properties

    static let suggestions = [
        String(localized: "Help me write an email"),
        String(localized: "Explain it simply"),
        String(localized: "Translate a text"),
        String(localized: "Plan my day"),
    ]

    @Published private(set) var state: State
    let events: AnyPublisher<Event, Never>

    private let chatRepository: any ChatRepository
    private let localStateRepository: any ChatLocalStateRepository
    private let premiumGate: any PremiumGating
    private let textCopier: any TextCopying
    private let eventSubject = PassthroughSubject<Event, Never>()
    /// Новый чат получает ID на клиенте; сервер может ответить своим.
    private var chatID: String
    private let isExistingChat: Bool
    private var messages: [ChatMessage] = []
    private var loadTask: Task<Void, Never>?
    private var generationTask: Task<Void, Never>?
    /// Локальные флаги обновляются по очереди, чтобы быстрые «закрепить» и «открепить» не поменялись местами.
    private var localStateTask: Task<Void, Never>?

    // MARK: - Init

    init(
        chat: Chat?,
        chatRepository: any ChatRepository,
        localStateRepository: any ChatLocalStateRepository,
        premiumGate: any PremiumGating,
        textCopier: any TextCopying
    ) {
        chatID = chat?.id ?? UUID().uuidString
        isExistingChat = chat != nil
        state = State(date: chat?.updatedAt ?? Date(), history: chat == nil ? .loaded([]) : .loading)
        self.chatRepository = chatRepository
        self.localStateRepository = localStateRepository
        self.premiumGate = premiumGate
        self.textCopier = textCopier
        events = eventSubject.eraseToAnyPublisher()
    }

    deinit {
        loadTask?.cancel()
        generationTask?.cancel()
    }

    // MARK: - API

    /// Загружает историю существующего чата и его локальные флаги. Возвращаемая задача нужна тестам.
    @discardableResult
    func load() -> Task<Void, Never> {
        loadTask?.cancel()
        if isExistingChat {
            update { $0.history = .loading }
        }
        let task = Task { [weak self, chatID, isExistingChat, chatRepository, localStateRepository] in
            let localState = await localStateRepository.load()
            self?.update { $0.isPinned = localState.pinnedChatIDs.contains(chatID) }
            guard isExistingChat else { return }
            do {
                let history = try await chatRepository.messages(inChat: chatID)
                guard !Task.isCancelled else { return }
                self?.showHistory(history)
            } catch {
                self?.showHistoryFailure(error)
            }
        }
        loadTask = task
        return task
    }

    func updateDraft(_ text: String) {
        guard text != state.draft else { return }
        update { $0.draft = text }
    }

    /// Подсказки заполняют поле ввода, но не отправляются, чтобы текст можно было сначала поправить.
    func applySuggestion(_ suggestion: String) {
        update { $0.draft = suggestion }
    }

    func sendTapped() {
        guard state.canSend else { return }
        premiumGate.perform { [weak self] in self?.send() }
    }

    func regenerateTapped() {
        guard !state.isGenerating, let prompt = lastPrompt else { return }
        premiumGate.perform { [weak self] in
            guard let self else { return }
            if messages.last?.role == .assistant {
                messages.removeLast()
            }
            generateReply(to: prompt)
        }
    }

    func retryTapped() {
        regenerateTapped()
    }

    func copyMessage(id: ChatMessage.ID) {
        guard let message = messages.first(where: { $0.id == id }) else { return }
        let isCopied = textCopier.copy(message.text)
        eventSubject.send(.showToast(isCopied ? .copied : .copyFailed))
    }

    func shareTapped() {
        guard !messages.isEmpty else { return }
        eventSubject.send(.share(ChatTranscript.text(of: messages)))
    }

    func togglePinTapped() {
        let isPinned = !state.isPinned
        update { $0.isPinned = isPinned }
        updateLocalState { [chatID] localState in
            if isPinned {
                localState.pinnedChatIDs.insert(chatID)
            } else {
                localState.pinnedChatIDs.remove(chatID)
            }
        }
    }

    func deleteTapped() {
        eventSubject.send(.confirmDeletion)
    }

    func deletionConfirmed() {
        updateLocalState { [chatID] localState in
            localState.deletedChatIDs.insert(chatID)
            localState.pinnedChatIDs.remove(chatID)
        }
        eventSubject.send(.deleted)
    }

    // MARK: - Private

    private var lastPrompt: String? {
        messages.last(where: { $0.role == .user })?.text
    }

    private func update(_ change: (inout State) -> Void) {
        var next = state
        change(&next)
        state = next
    }

    private func send() {
        let text = state.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !state.isGenerating else { return }
        messages.append(ChatMessage(id: UUID().uuidString, role: .user, text: text, createdAt: Date()))
        update { $0.draft = "" }
        generateReply(to: text)
    }

    private func generateReply(to prompt: String) {
        update {
            $0.isGenerating = true
            $0.items = items(trailing: .typing)
        }
        generationTask = Task { [weak self, chatID, chatRepository] in
            do {
                let reply = try await chatRepository.sendMessage(prompt, toChat: chatID)
                self?.showReply(reply)
            } catch {
                self?.showGenerationFailure(error)
            }
        }
    }

    private func showHistory(_ history: [ChatMessage]) {
        messages = history
        update {
            $0.history = .loaded(history)
            $0.items = items(trailing: nil)
        }
    }

    private func showHistoryFailure(_ error: any Error) {
        guard let userFacingError = UserFacingError(error) else { return }
        update { $0.history = .failed(userFacingError) }
    }

    private func showReply(_ reply: ChatReply) {
        chatID = reply.chatID
        messages.append(ChatMessage(id: UUID().uuidString, role: .assistant, text: reply.text, createdAt: Date()))
        update {
            $0.isGenerating = false
            $0.items = items(trailing: nil)
        }
    }

    private func showGenerationFailure(_ error: any Error) {
        let userFacingError = UserFacingError(error)
        update {
            $0.isGenerating = false
            $0.items = items(trailing: userFacingError.map(ChatItem.failure))
        }
    }

    /// Перегенерировать можно только ответ на последний запрос.
    private func items(trailing trailingItem: ChatItem?) -> [ChatItem] {
        let lastIndex = messages.indices.last
        var items = messages.enumerated().map { index, message in
            ChatItem.message(message, canRegenerate: message.role == .assistant && index == lastIndex && trailingItem == nil)
        }
        if let trailingItem {
            items.append(trailingItem)
        }
        return items
    }

    private func updateLocalState(_ change: @escaping @Sendable (inout ChatLocalState) -> Void) {
        let previousTask = localStateTask
        localStateTask = Task { [localStateRepository] in
            await previousTask?.value
            var localState = await localStateRepository.load()
            change(&localState)
            // Неудачная запись теряет флаг только до следующего запуска; экран его уже показывает.
            try? await localStateRepository.save(localState)
        }
    }
}
