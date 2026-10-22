import AVFoundation
import Combine
import OSLog
import UIKit

/// Проигрывает беззвучные зацикленные видео в самых заметных ячейках коллекции. Плееры берутся
/// из фиксированного пула и выдаются `VideoPreviewView`, поэтому память не растёт, какой бы длинной ни была лента.
@MainActor
final class AutoplayController {
    // MARK: - Types

    private enum Threshold {
        /// Ячейка, видимая меньше чем на эту долю, не стоит декодера.
        static let minVisibleFraction: CGFloat = 0.3
    }

    private final class Slot {
        let player = AVQueuePlayer()
        var looper: AVPlayerLooper?
        weak var view: VideoPreviewView?
        var url: URL?
        var loadTask: Task<Void, Never>?

        init() {
            player.isMuted = true
            player.preventsDisplaySleepDuringVideoPlayback = false
        }
    }

    // MARK: - Properties

    private weak var collectionView: UICollectionView?
    private let slots: [Slot]
    private let cache: VideoCache
    private var isSuspended = true
    private var isAppInBackground = false
    private var cancellables: Set<AnyCancellable> = []
    private let logger = Logger(category: "AutoplayController")

    // MARK: - Init

    /// `maxPlayers` должен покрывать ячейки, которые помещаются на экране одновременно.
    init(maxPlayers: Int, cache: VideoCache) {
        slots = (0..<maxPlayers).map { _ in Slot() }
        self.cache = cache
        observeAppState()
    }

    // MARK: - API

    func attach(to collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    /// Вызывать после прокрутки, показа и скрытия ячеек и после применения снапшота.
    func refresh() {
        guard !isSuspended, !isAppInBackground, let collectionView else { return }

        let targets = mostVisiblePreviews(in: collectionView)
        let targetIDs = Set(targets.map(ObjectIdentifier.init))
        for slot in slots where !isServing(slot, targetIDs: targetIDs) {
            release(slot)
        }

        let servedIDs = Set(slots.compactMap { $0.view.map(ObjectIdentifier.init) })
        var freeSlots = slots.filter { $0.view == nil }
        for view in targets where !servedIDs.contains(ObjectIdentifier(view)) {
            guard let url = view.videoURL, !freeSlots.isEmpty else { break }
            assign(freeSlots.removeFirst(), to: view, url: url)
        }
    }

    func resume() {
        isSuspended = false
        refresh()
    }

    /// Останавливает воспроизведение и убирает все элементы, чтобы экран в фоне не держал декодеры.
    func suspend() {
        isSuspended = true
        slots.forEach(release)
    }

    // MARK: - Private

    /// Система и так ставит видео на паузу в фоне; если убрать элементы, освободятся и декодеры.
    private func observeAppState() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                isAppInBackground = true
                slots.forEach(release)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.isAppInBackground = false
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    private func mostVisiblePreviews(in collectionView: UICollectionView) -> [VideoPreviewView] {
        let visibleRect = collectionView.bounds
        return collectionView.visibleCells
            .compactMap { ($0 as? VideoPreviewProviding)?.videoPreview }
            .filter { $0.videoURL != nil && !$0.isHidden }
            .map { view in (view, Self.visibleFraction(of: view, in: visibleRect, of: collectionView)) }
            .filter { $0.1 >= Threshold.minVisibleFraction }
            .sorted { $0.1 > $1.1 }
            .prefix(slots.count)
            .map(\.0)
    }

    private static func visibleFraction(of view: UIView, in visibleRect: CGRect, of collectionView: UICollectionView) -> CGFloat {
        let frame = view.convert(view.bounds, to: collectionView)
        let area = frame.width * frame.height
        let visible = frame.intersection(visibleRect)
        guard area > 0, !visible.isNull else { return 0 }
        return visible.width * visible.height / area
    }

    private func isServing(_ slot: Slot, targetIDs: Set<ObjectIdentifier>) -> Bool {
        guard let view = slot.view else { return false }
        return targetIDs.contains(ObjectIdentifier(view)) && view.videoURL == slot.url
    }

    private func assign(_ slot: Slot, to view: VideoPreviewView, url: URL) {
        slot.view = view
        slot.url = url
        view.attach(slot.player)
        slot.loadTask = Task { [weak self, cache] in
            do {
                let fileURL = try await cache.localURL(for: url)
                guard !Task.isCancelled else { return }
                self?.play(fileURL, in: slot)
            } catch {
                self?.logger.error("Failed to load video preview: \(error)")
            }
        }
    }

    private func play(_ fileURL: URL, in slot: Slot) {
        slot.looper = AVPlayerLooper(player: slot.player, templateItem: AVPlayerItem(url: fileURL))
        // Если автовоспроизведение отключено в универсальном доступе, первый кадр всё равно виден, на паузе.
        if UIAccessibility.isVideoAutoplayEnabled {
            slot.player.play()
        }
    }

    private func release(_ slot: Slot) {
        slot.loadTask?.cancel()
        slot.loadTask = nil
        slot.looper?.disableLooping()
        slot.looper = nil
        slot.player.pause()
        slot.player.removeAllItems()
        slot.view?.attach(nil)
        slot.view = nil
        slot.url = nil
    }
}
