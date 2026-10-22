import Combine
import Foundation

@MainActor
final class VideoTemplateViewModel {
    // MARK: - Types

    enum PhotoState: Equatable {
        case empty
        case loading
        /// Экран показывает маленький JPEG; полное фото остаётся во ViewModel.
        case loaded(thumbnail: Data)
    }

    struct State: Equatable {
        /// Шаблоны, между которыми можно листать: категория, из которой открыт экран.
        let templates: [VideoTemplate]
        var template: VideoTemplate
        var photo = PhotoState.empty
        var format = VideoFormat.landscape
        var quality: VideoQuality
        var isStarting = false

        var currentIndex: Int {
            templates.firstIndex(of: template) ?? 0
        }

        var canCreate: Bool {
            guard case .loaded = photo else { return false }
            return !isStarting
        }
    }

    enum Toast: Equatable {
        case uploadFailed
    }

    enum Event: Equatable {
        case showPhotoPicker
        /// Доступ запретили раньше; теперь выдать его можно только в «Настройках».
        case showPhotoAccessDenied
        case showToast(Toast)
        case showError(UserFacingError)
        case openGeneration(VideoGeneration.ID)
    }

    // MARK: - Properties

    @Published private(set) var state: State
    let events: AnyPublisher<Event, Never>

    private let generator: any VideoGenerating
    private let premiumGate: any PremiumGating
    private let photoAccess: any PhotoLibraryAccessProviding
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var photoData: Data?
    private var photoTask: Task<Void, Never>?
    private var startTask: Task<Void, Never>?

    // MARK: - Init

    /// `templates` — список для листания; если в нём нет `template`, остаётся только он.
    init(
        template: VideoTemplate,
        templates: [VideoTemplate],
        generator: any VideoGenerating,
        premiumGate: any PremiumGating,
        photoAccess: any PhotoLibraryAccessProviding
    ) {
        state = State(
            templates: templates.contains(template) ? templates : [template],
            template: template,
            quality: Self.quality(for: template, keeping: nil)
        )
        self.generator = generator
        self.premiumGate = premiumGate
        self.photoAccess = photoAccess
        events = eventSubject.eraseToAnyPublisher()
    }

    deinit {
        photoTask?.cancel()
    }

    // MARK: - API

    func selectTemplate(at index: Int) {
        guard state.templates.indices.contains(index), index != state.currentIndex else { return }
        let template = state.templates[index]
        update {
            $0.template = template
            $0.quality = Self.quality(for: template, keeping: $0.quality)
        }
    }

    @discardableResult
    func addPhotoTapped() -> Task<Void, Never>? {
        switch photoAccess.currentAccess() {
        case .granted:
            eventSubject.send(.showPhotoPicker)
            return nil
        case .denied:
            eventSubject.send(.showPhotoAccessDenied)
            return nil
        case .notDetermined:
            return Task { [weak self, photoAccess] in
                // Отказ в системном запросе оставляет экран как был.
                guard await photoAccess.requestAccess() == .granted else { return }
                self?.eventSubject.send(.showPhotoPicker)
            }
        }
    }

    /// `load` читает выбранное фото; пока он не закончит, экран показывает прогресс.
    @discardableResult
    func loadPhoto(_ load: @escaping @MainActor () async throws -> LoadedPhoto) -> Task<Void, Never> {
        photoTask?.cancel()
        photoData = nil
        update { $0.photo = .loading }
        let task = Task { [weak self] in
            do {
                let photo = try await load()
                guard !Task.isCancelled else { return }
                self?.showPhoto(photo)
            } catch {
                guard !Task.isCancelled else { return }
                self?.showPhotoFailure()
            }
        }
        photoTask = task
        return task
    }

    func removePhoto() {
        photoTask?.cancel()
        photoData = nil
        update { $0.photo = .empty }
    }

    func selectFormat(_ format: VideoFormat) {
        update { $0.format = format }
    }

    func selectQuality(_ quality: VideoQuality) {
        guard state.template.qualities.contains(quality) else { return }
        update { $0.quality = quality }
    }

    /// Возвращает задачу, которая добавляет генерацию, или `nil`, если ничего не запустилось.
    @discardableResult
    func createTapped() -> Task<Void, Never>? {
        guard state.canCreate, let photoData else { return nil }
        startTask = nil
        premiumGate.perform { [weak self] in
            self?.startGeneration(photo: photoData)
        }
        return startTask
    }

    // MARK: - Private

    /// Сохраняет текущее качество, если шаблон его поддерживает, иначе выбирает рекомендуемое.
    private static func quality(for template: VideoTemplate, keeping current: VideoQuality?) -> VideoQuality {
        if let current, template.qualities.contains(current) {
            return current
        }
        if template.qualities.contains(.recommended) {
            return .recommended
        }
        return template.qualities.max() ?? .recommended
    }

    private func update(_ change: (inout State) -> Void) {
        var next = state
        change(&next)
        state = next
    }

    private func showPhoto(_ photo: LoadedPhoto) {
        photoData = photo.jpegData
        update { $0.photo = .loaded(thumbnail: photo.thumbnailData) }
    }

    private func showPhotoFailure() {
        update { $0.photo = .empty }
        eventSubject.send(.showToast(.uploadFailed))
    }

    private func startGeneration(photo: Data) {
        let request = VideoGenerationRequest(
            templateID: state.template.id,
            templateName: state.template.name,
            format: state.format,
            quality: state.quality,
            photo: photo
        )
        update { $0.isStarting = true }
        startTask = Task { [weak self, generator] in
            do {
                let id = try await generator.generate(request)
                self?.finishStarting()
                self?.eventSubject.send(.openGeneration(id))
            } catch {
                self?.finishStarting()
                self?.showStartFailure(error)
            }
        }
    }

    private func finishStarting() {
        update { $0.isStarting = false }
    }

    private func showStartFailure(_ error: any Error) {
        guard let userFacingError = UserFacingError(error) else { return }
        eventSubject.send(.showError(userFacingError))
    }
}
