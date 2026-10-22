import Combine
import Foundation

@MainActor
final class VideoTemplatesViewModel {
    // MARK: - Types

    struct State: Equatable {
        var templates: Loadable<[VideoTemplate]> = .loading
        var selectedCategory: String?

        /// Категории в порядке каталога.
        var categories: [String] {
            var seen = Set<String>()
            return (templates.value ?? []).map(\.category).filter { seen.insert($0).inserted }
        }

        /// Шаблоны выбранной категории. Шаблон, указанный дважды, показывается один раз.
        var visibleTemplates: [VideoTemplate] {
            var seen = Set<VideoTemplate.ID>()
            return (templates.value ?? []).filter { $0.category == selectedCategory && seen.insert($0.id).inserted }
        }
    }

    enum Event: Equatable {
        /// `templates` — шаблоны выбранной категории, чтобы экран шаблона мог листать между ними.
        case openTemplate(templates: [VideoTemplate], index: Int)
    }

    // MARK: - Properties

    @Published private(set) var state = State()
    let events: AnyPublisher<Event, Never>

    private let repository: any VideoTemplateRepository
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var loadTask: Task<Void, Never>?

    // MARK: - Init

    init(repository: any VideoTemplateRepository) {
        self.repository = repository
        events = eventSubject.eraseToAnyPublisher()
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - API

    @discardableResult
    func load() -> Task<Void, Never> {
        loadTask?.cancel()
        update { $0.templates = .loading }
        let task = Task { [weak self, repository] in
            do {
                let templates = try await repository.templates()
                guard !Task.isCancelled else { return }
                self?.show(templates)
            } catch {
                self?.showFailure(error)
            }
        }
        loadTask = task
        return task
    }

    func selectCategory(_ category: String) {
        guard category != state.selectedCategory, state.categories.contains(category) else { return }
        update { $0.selectedCategory = category }
    }

    func selectTemplate(id: VideoTemplate.ID) {
        let templates = state.visibleTemplates
        guard let index = templates.firstIndex(where: { $0.id == id }) else { return }
        eventSubject.send(.openTemplate(templates: templates, index: index))
    }

    // MARK: - Private

    private func update(_ change: (inout State) -> Void) {
        var next = state
        change(&next)
        state = next
    }

    private func show(_ templates: [VideoTemplate]) {
        update {
            $0.templates = .loaded(templates)
            // По умолчанию выбрана первая категория; при перезагрузке выбор пользователя сохраняется.
            if let selected = $0.selectedCategory, $0.categories.contains(selected) { return }
            $0.selectedCategory = $0.categories.first
        }
    }

    private func showFailure(_ error: any Error) {
        guard let userFacingError = UserFacingError(error) else { return }
        update { $0.templates = .failed(userFacingError) }
    }
}
