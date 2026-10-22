import Combine
import Foundation

@MainActor
final class SettingsViewModel {
    // MARK: - Types

    struct State: Equatable {
        /// `nil`, пока не измерено.
        var cacheSize: String?
        var areNotificationsOn = false
        var isRestoring = false
        let appVersion: String
    }

    enum Toast: Equatable {
        case cacheCleared
        case purchasesRestored
    }

    enum Event: Equatable {
        case openPaywall
        case requestReview
        case shareApp
        /// После ответа на системный запрос разрешение можно изменить только там.
        case openSystemSettings
        case showToast(Toast)
        case showError(UserFacingError)
    }

    // MARK: - Properties

    @Published private(set) var state: State
    let events: AnyPublisher<Event, Never>

    private let subscriptionService: any SubscriptionPurchasing
    private let cache: any CacheClearing
    private let notifications: any NotificationPermissionProviding
    private let eventSubject = PassthroughSubject<Event, Never>()

    // MARK: - Init

    init(
        subscriptionService: any SubscriptionPurchasing,
        cache: any CacheClearing,
        notifications: any NotificationPermissionProviding,
        appVersion: String
    ) {
        self.subscriptionService = subscriptionService
        self.cache = cache
        self.notifications = notifications
        state = State(appVersion: appVersion)
        events = eventSubject.eraseToAnyPublisher()
    }

    // MARK: - API

    /// Измеряет кэш и читает разрешение на уведомления; вызывается снова, когда приложение возвращается
    /// из «Настроек». Возвращаемая задача нужна тестам.
    @discardableResult
    func refresh() -> Task<Void, Never> {
        Task { [weak self, cache, notifications] in
            async let size = cache.cacheSize()
            let permission = await notifications.currentPermission()
            let cacheSize = await size
            self?.update {
                $0.areNotificationsOn = permission == .allowed
                $0.cacheSize = Self.format(cacheSize)
            }
        }
    }

    func upgradeTapped() {
        eventSubject.send(.openPaywall)
    }

    func rateTapped() {
        eventSubject.send(.requestReview)
    }

    func shareTapped() {
        eventSubject.send(.shareApp)
    }

    @discardableResult
    func setNotificationsEnabled(_ isEnabled: Bool) -> Task<Void, Never>? {
        guard isEnabled else {
            eventSubject.send(.openSystemSettings)
            return nil
        }
        return Task { [weak self, notifications] in
            var permission = await notifications.currentPermission()
            if permission == .notDetermined {
                permission = await notifications.requestPermission()
            }
            if permission == .denied {
                self?.eventSubject.send(.openSystemSettings)
            }
            self?.update { $0.areNotificationsOn = permission == .allowed }
        }
    }

    @discardableResult
    func clearCacheTapped() -> Task<Void, Never> {
        Task { [weak self, cache] in
            await cache.clearCache()
            let size = await cache.cacheSize()
            self?.update { $0.cacheSize = Self.format(size) }
            self?.eventSubject.send(.showToast(.cacheCleared))
        }
    }

    @discardableResult
    func restoreTapped() -> Task<Void, Never>? {
        guard !state.isRestoring else { return nil }
        update { $0.isRestoring = true }
        return Task { [weak self, subscriptionService] in
            do {
                try await subscriptionService.restorePurchases()
                self?.eventSubject.send(.showToast(.purchasesRestored))
            } catch {
                if let userFacingError = UserFacingError(error) {
                    self?.eventSubject.send(.showError(userFacingError))
                }
            }
            self?.update { $0.isRestoring = false }
        }
    }

    // MARK: - Private

    private static func format(_ bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file))
    }

    private func update(_ change: (inout State) -> Void) {
        var next = state
        change(&next)
        state = next
    }
}
