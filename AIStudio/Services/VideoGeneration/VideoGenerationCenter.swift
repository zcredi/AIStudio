import Combine
import Foundation
import OSLog

/// Владеет генерациями видео всё время жизни приложения: загружает стартовый кадр, опрашивает сервер,
/// скачивает результат и ведёт историю. Экраны только наблюдают, поэтому уход
/// с экрана генерации ничего не отменяет.
@MainActor
final class VideoGenerationCenter: VideoGenerating {
    // MARK: - Types

    private enum StartFrame {
        /// Длинная сторона загружаемого кадра: хватает на 1080p в любом формате.
        static let maxPixelSize = 2560
    }

    // MARK: - Properties

    var generationsPublisher: AnyPublisher<[VideoGeneration], Never> {
        $generations.eraseToAnyPublisher()
    }

    @Published private(set) var generations: [VideoGeneration] = []

    private let repository: any VideoGenerationRepository
    private let library: any VideoLibraryRepository
    private let poller: Poller
    private let now: () -> Date
    private var tasks: [VideoGeneration.ID: Task<Void, Never>] = [:]
    private var saveTask: Task<Void, Never>?
    private let logger = Logger(category: "VideoGenerationCenter")

    // MARK: - Init

    init(
        repository: any VideoGenerationRepository,
        library: any VideoLibraryRepository,
        poller: Poller = Poller(policy: .videoGeneration),
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.library = library
        self.poller = poller
        self.now = now
    }

    // MARK: - API

    /// Загружает историю и продолжает генерации, которые шли, когда приложение закрылось.
    @discardableResult
    func start() -> Task<Void, Never> {
        Task { [weak self, library] in
            let saved = await library.generations()
            self?.restore(saved)
        }
    }

    // MARK: - VideoGenerating

    func generate(_ request: VideoGenerationRequest) async throws -> VideoGeneration.ID {
        let id = UUID()
        let frame = try await ImageCropper.jpegData(
            from: request.photo,
            croppedTo: request.format.aspectRatio,
            maxPixelSize: StartFrame.maxPixelSize
        )
        try await library.saveStartFrame(frame, for: id)

        let generation = VideoGeneration(
            id: id,
            templateID: request.templateID,
            templateName: request.templateName,
            format: request.format,
            quality: request.quality,
            createdAt: now(),
            state: .inProgress,
            remoteID: nil,
            isNew: false
        )
        generations.insert(generation, at: 0)
        persist()
        run(generation)
        return id
    }

    func retry(_ id: VideoGeneration.ID) {
        guard tasks[id] == nil, let generation = generation(id), generation.state == .failed else { return }
        update(id) {
            $0.state = .inProgress
            $0.failure = nil
        }
        run(generation)
    }

    func markSeen(_ id: VideoGeneration.ID) {
        guard generation(id)?.isNew == true else { return }
        update(id) { $0.isNew = false }
    }

    func videoURL(for id: VideoGeneration.ID) -> URL {
        library.videoURL(for: id)
    }

    func startFrameURL(for id: VideoGeneration.ID) -> URL {
        library.startFrameURL(for: id)
    }

    // MARK: - Private

    private func generation(_ id: VideoGeneration.ID) -> VideoGeneration? {
        generations.first { $0.id == id }
    }

    private func restore(_ saved: [VideoGeneration]) {
        let restored = saved.map { generation in
            var generation = generation
            // Без серверного ID загрузка так и не закончилась; повторять или нет, решает пользователь.
            if generation.state == .inProgress, generation.remoteID == nil {
                generation.state = .failed
                generation.failure = .interrupted
            }
            return generation
        }
        // Генерация, запущенная до окончания загрузки истории, остаётся наверху.
        let startedIDs = Set(generations.map(\.id))
        generations += restored.filter { !startedIDs.contains($0.id) }
        restored.filter { $0.state == .inProgress }.forEach(run)
    }

    private func run(_ generation: VideoGeneration) {
        let id = generation.id
        tasks[id] = Task { [weak self, repository, library, poller] in
            do {
                let remoteID: Int
                if let savedID = generation.remoteID {
                    remoteID = savedID
                } else {
                    let frame = try await library.startFrame(for: id)
                    remoteID = try await repository.startGeneration(
                        templateID: generation.templateID,
                        image: frame,
                        quality: generation.quality
                    )
                    self?.update(id) { $0.remoteID = remoteID }
                }
                let videoURL = try await Self.result(of: remoteID, repository: repository, poller: poller)
                try await library.downloadVideo(from: videoURL, for: id)
                self?.finish(id, error: nil)
            } catch {
                self?.finish(id, error: error)
            }
        }
    }

    private nonisolated static func result(
        of remoteID: Int,
        repository: any VideoGenerationRepository,
        poller: Poller
    ) async throws -> URL {
        let status = try await poller.poll {
            let status = try await repository.status(ofGeneration: remoteID)
            return status == .generating ? nil : status
        }
        guard case .succeeded(let videoURL) = status else { throw VideoGenerationError.renderingFailed }
        return videoURL
    }

    private func finish(_ id: VideoGeneration.ID, error: (any Error)?) {
        tasks[id] = nil
        guard let error else {
            update(id) {
                $0.state = .ready
                $0.isNew = true
            }
            return
        }
        guard !(error is CancellationError) else { return }

        logger.error("Video generation failed: \(error)")
        // Упавшую или истёкшую задачу на сервере надёжно не продолжить, поэтому повтор запускает новую.
        update(id) {
            $0.state = .failed
            $0.remoteID = nil
            $0.failure = Self.failure(for: error)
        }
    }

    /// Сводит ошибки сети, опроса и сервера к причине, которую можно объяснить пользователю.
    private static func failure(for error: any Error) -> VideoGenerationError {
        if let error = error as? VideoGenerationError {
            return error
        }
        if error is PollingError {
            return .timedOut
        }
        switch error as? APIError {
        case .offline:
            return .offline
        case .timeout:
            return .timedOut
        case .insufficientCredits:
            return .insufficientCredits
        default:
            return .unknown
        }
    }

    private func update(_ id: VideoGeneration.ID, _ change: (inout VideoGeneration) -> Void) {
        guard let index = generations.firstIndex(where: { $0.id == id }) else { return }
        change(&generations[index])
        persist()
    }

    /// Сохранения идут цепочкой, чтобы старый снимок никогда не перезаписал новый.
    private func persist() {
        let snapshot = generations
        let previousSave = saveTask
        saveTask = Task { [library, logger] in
            await previousSave?.value
            do {
                try await library.save(snapshot)
            } catch {
                logger.error("Failed to save video history: \(error)")
            }
        }
    }
}
