import Combine
import Foundation

@MainActor
final class HistoryViewModel {
    // MARK: - Types

    enum Tab: Int, CaseIterable, Sendable {
        case chats
        case videos
    }

    struct VideoItem: Identifiable, Equatable {
        let id: VideoGeneration.ID
        let title: String
        let state: VideoGeneration.State
        let isNew: Bool
        /// Ширина, делённая на высоту.
        let aspectRatio: Double
        let videoURL: URL
        let startFrameURL: URL
    }

    struct State: Equatable {
        var selectedTab = Tab.chats
        var chats: Loadable<[ChatHistorySection]> = .loading
        /// Локальные, поэтому никогда не загружаются и не падают; от новых к старым.
        var videos: [VideoItem] = []
    }

    enum Event: Equatable {
        case openChat(Chat)
        case openVideo(VideoGeneration)
        case openGeneration(VideoGeneration.ID)
    }

    // MARK: - Properties

    @Published private(set) var state = State()
    let events: AnyPublisher<Event, Never>

    private let chatRepository: any ChatRepository
    private let localStateRepository: any ChatLocalStateRepository
    private let generator: any VideoGenerating
    private let premiumGate: any PremiumGating
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var generations: [VideoGeneration] = []
    private var videosSubscription: AnyCancellable?
    private var chats: [Chat] = []
    private var localState = ChatLocalState()
    private var loadTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?

    // MARK: - Init

    init(
        chatRepository: any ChatRepository,
        localStateRepository: any ChatLocalStateRepository,
        generator: any VideoGenerating,
        premiumGate: any PremiumGating
    ) {
        self.chatRepository = chatRepository
        self.localStateRepository = localStateRepository
        self.generator = generator
        self.premiumGate = premiumGate
        events = eventSubject.eraseToAnyPublisher()
        videosSubscription = generator.generationsPublisher
            .sink { [weak self] in self?.showVideos($0) }
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - API

    /// Кнопка Save неактивна, пока в названии нет видимых символов.
    static func isValidTitle(_ title: String) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Skeleton только при первой загрузке; при обновлениях список остаётся на экране.
    @discardableResult
    func load() -> Task<Void, Never> {
        loadTask?.cancel()
        if state.chats.value == nil {
            update { $0.chats = .loading }
        }
        let task = Task { [weak self, chatRepository, localStateRepository, saveTask] in
            do {
                async let chats = chatRepository.chats()
                // Локальные правки, сделанные только что, должны лечь на диск раньше, чем их прочитают обратно.
                await saveTask?.value
                let localState = await localStateRepository.load()
                let loadedChats = try await chats
                guard !Task.isCancelled else { return }
                self?.show(loadedChats, localState: localState)
            } catch {
                self?.showFailure(error)
            }
        }
        loadTask = task
        return task
    }

    func selectTab(_ tab: Tab) {
        guard tab != state.selectedTab else { return }
        update { $0.selectedTab = tab }
    }

    func selectChat(id: Chat.ID) {
        guard let chat = chats.first(where: { $0.id == id }) else { return }
        eventSubject.send(.openChat(chat))
    }

    /// Готовое видео открывает результат, а видео в процессе — экран генерации.
    /// Упавшая карточка вместо этого предлагает «Try again».
    func selectVideo(id: VideoGeneration.ID) {
        guard let generation = generations.first(where: { $0.id == id }) else { return }
        switch generation.state {
        case .ready:
            eventSubject.send(.openVideo(generation))
        case .inProgress:
            eventSubject.send(.openGeneration(id))
        case .failed:
            break
        }
    }

    /// Повтор тратит кредиты, как новая генерация, поэтому это тоже премиум-действие.
    func retryVideo(id: VideoGeneration.ID) {
        premiumGate.perform { [generator] in
            generator.retry(id)
        }
    }

    func renameChat(id: Chat.ID, to title: String) {
        guard Self.isValidTitle(title) else { return }
        localState.customTitles[id] = title.trimmingCharacters(in: .whitespacesAndNewlines)
        saveLocalStateAndRefresh()
    }

    func deleteChat(id: Chat.ID) {
        localState.deletedChatIDs.insert(id)
        localState.pinnedChatIDs.remove(id)
        saveLocalStateAndRefresh()
    }

    // MARK: - Private

    private func update(_ change: (inout State) -> Void) {
        var next = state
        change(&next)
        state = next
    }

    private func show(_ chats: [Chat], localState: ChatLocalState) {
        self.chats = chats
        self.localState = localState
        rebuildSections()
    }

    private func showFailure(_ error: any Error) {
        guard let userFacingError = UserFacingError(error) else { return }
        // Неудачное обновление оставляет на экране уже показанный список.
        guard state.chats.value == nil else { return }
        update { $0.chats = .failed(userFacingError) }
    }

    private func showVideos(_ generations: [VideoGeneration]) {
        self.generations = generations
        let videos = generations.map { generation in
            VideoItem(
                id: generation.id,
                title: generation.templateName,
                state: generation.state,
                isNew: generation.isNew,
                aspectRatio: generation.format.aspectRatio,
                videoURL: generator.videoURL(for: generation.id),
                startFrameURL: generator.startFrameURL(for: generation.id)
            )
        }
        update { $0.videos = videos }
    }

    private func rebuildSections() {
        let sections = ChatHistorySection.sections(for: chats, localState: localState)
        update { $0.chats = .loaded(sections) }
    }

    private func saveLocalStateAndRefresh() {
        rebuildSections()
        let previousTask = saveTask
        saveTask = Task { [localStateRepository, localState] in
            await previousTask?.value
            // Неудачная запись теряет изменение только до следующего запуска; список его уже показывает.
            try? await localStateRepository.save(localState)
        }
    }
}
