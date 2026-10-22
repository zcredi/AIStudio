import Combine
import Foundation

@MainActor
final class VideoResultViewModel {
    // MARK: - Types

    struct State: Equatable {
        let videoURL: URL
        let format: VideoFormat
        var isPlaying = false
        var isSaving = false
        /// Новое фото для «Replace» загружается или стартует его генерация.
        var isReplacing = false
    }

    enum SaveResult: Equatable {
        case saved
        case failed
        case accessDenied
    }

    enum Toast: Equatable {
        case uploadFailed
    }

    enum Event: Equatable {
        case share(URL)
        case showSaveResult(SaveResult)
        case showPhotoPicker
        case showPhotoAccessDenied
        case showToast(Toast)
        case showError(UserFacingError)
        case openGeneration(VideoGeneration.ID)
    }

    // MARK: - Properties

    @Published private(set) var state: State
    let events: AnyPublisher<Event, Never>

    private let generation: VideoGeneration
    private let generator: any VideoGenerating
    private let saver: any VideoSaving
    private let premiumGate: any PremiumGating
    private let photoAccess: any PhotoLibraryAccessProviding
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var replaceTask: Task<Void, Never>?

    // MARK: - Init

    init(
        generation: VideoGeneration,
        generator: any VideoGenerating,
        saver: any VideoSaving,
        premiumGate: any PremiumGating,
        photoAccess: any PhotoLibraryAccessProviding
    ) {
        self.generation = generation
        self.generator = generator
        self.saver = saver
        self.premiumGate = premiumGate
        self.photoAccess = photoAccess
        state = State(videoURL: generator.videoURL(for: generation.id), format: generation.format)
        events = eventSubject.eraseToAnyPublisher()
    }

    deinit {
        replaceTask?.cancel()
    }

    // MARK: - API

    /// Результат считается просмотренным, как только показан его экран, поэтому история убирает плашку «New».
    func viewDidAppear() {
        generator.markSeen(generation.id)
    }

    func togglePlayback() {
        update { $0.isPlaying.toggle() }
    }

    func pause() {
        update { $0.isPlaying = false }
    }

    func shareTapped() {
        eventSubject.send(.share(state.videoURL))
    }

    @discardableResult
    func downloadTapped() -> Task<Void, Never>? {
        guard !state.isSaving else { return nil }
        update { $0.isSaving = true }
        return Task { [weak self, saver, videoURL = state.videoURL] in
            let result: SaveResult
            do {
                try await saver.saveVideo(at: videoURL)
                result = .saved
            } catch VideoSavingError.accessDenied {
                result = .accessDenied
            } catch {
                result = .failed
            }
            self?.update { $0.isSaving = false }
            self?.eventSubject.send(.showSaveResult(result))
        }
    }

    /// «Replace» выбирает новое фото и запускает генерацию заново с тем же шаблоном, форматом и качеством.
    @discardableResult
    func replaceTapped() -> Task<Void, Never>? {
        guard !state.isReplacing else { return nil }
        var accessTask: Task<Void, Never>?
        premiumGate.perform { [weak self] in
            accessTask = self?.requestPhoto()
        }
        return accessTask
    }

    @discardableResult
    func replacePhoto(_ load: @escaping @MainActor () async throws -> LoadedPhoto) -> Task<Void, Never> {
        replaceTask?.cancel()
        update {
            $0.isReplacing = true
            $0.isPlaying = false
        }
        let task = Task { [weak self] in
            let photo: LoadedPhoto
            do {
                photo = try await load()
            } catch {
                guard !Task.isCancelled else { return }
                self?.update { $0.isReplacing = false }
                self?.eventSubject.send(.showToast(.uploadFailed))
                return
            }
            await self?.generate(with: photo)
        }
        replaceTask = task
        return task
    }

    // MARK: - Private

    private func update(_ change: (inout State) -> Void) {
        var next = state
        change(&next)
        state = next
    }

    private func requestPhoto() -> Task<Void, Never>? {
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

    private func generate(with photo: LoadedPhoto) async {
        let request = VideoGenerationRequest(
            templateID: generation.templateID,
            templateName: generation.templateName,
            format: generation.format,
            quality: generation.quality,
            photo: photo.jpegData
        )
        do {
            let id = try await generator.generate(request)
            update { $0.isReplacing = false }
            eventSubject.send(.openGeneration(id))
        } catch {
            update { $0.isReplacing = false }
            showFailure(error)
        }
    }

    private func showFailure(_ error: any Error) {
        guard let userFacingError = UserFacingError(error) else { return }
        eventSubject.send(.showError(userFacingError))
    }
}
